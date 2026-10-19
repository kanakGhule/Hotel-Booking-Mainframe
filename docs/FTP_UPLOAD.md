# HRBS - z/OS FTP Upload and Dataset Provisioning Guide

This guide details how to transfer source code, scripts, and test data from your local Windows workstation to IBM z/OS using standard FTP.

---

## 1. Prerequisites on z/OS

Ensure your TSO user ID is authorized and that datasets are pre-allocated (using [ALLOCATE.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/ALLOCATE.jcl) or ISPF 3.2):
- `<userid>.HRBS.COBOL` (PO, RECFM=FB, LRECL=80)
- `<userid>.HRBS.COBOL.DCLGEN` (PO, RECFM=FB, LRECL=80)
- `<userid>.HRBS.REXX` (PO, RECFM=FB, LRECL=80)
- `<userid>.HRBS.LOAD` (PO, RECFM=U, BLKSIZE=32760)

---

## 2. Interactive FTP Session Step-by-Step

Open Command Prompt or PowerShell in the project root directory and run:

```cmd
ftp <zos-host-or-ip>
```

Enter your z/OS User ID and Password when prompted.

### Step 2.1: Configure Transfer Parameters
Always use **ASCII** mode for source code and fixed-block text data so the FTP server automatically converts ASCII to EBCDIC.

```text
ascii
prompt off
```

### Step 2.2: Upload COBOL Programs to PDS
```text
quote site recfm=fb lrecl=80 blksize=0
put cobol/HRBSMTCH.cbl 'HRBS.COBOL(HRBSMTCH)'
put cobol/HRBSBIL.cbl  'HRBS.COBOL(HRBSBIL)'
put cobol/HRBSVAL.cbl  'HRBS.COBOL(HRBSVAL)'
put cobol/HRBSUPD.cbl  'HRBS.COBOL(HRBSUPD)'
put cobol/HRBSRPT.cbl  'HRBS.COBOL(HRBSRPT)'
put cobol/HRBSDB2.cbl  'HRBS.COBOL(HRBSDB2)'
```

### Step 2.3: Upload DCLGEN Copybooks
```text
put cobol/dclgen/DCLGUEST.cbl 'HRBS.COBOL.DCLGEN(DCLGUEST)'
put cobol/dclgen/DCLROOM.cbl  'HRBS.COBOL.DCLGEN(DCLROOM)'
put cobol/dclgen/DCLRESV.cbl  'HRBS.COBOL.DCLGEN(DCLRESV)'
put cobol/dclgen/DCLBILL.cbl  'HRBS.COBOL.DCLGEN(DCLBILL)'
put cobol/dclgen/DCLPAY.cbl   'HRBS.COBOL.DCLGEN(DCLPAY)'
```

### Step 2.4: Upload REXX Procedures
```text
put rexx/HRBSDEDP.rexx 'HRBS.REXX(HRBSDEDP)'
put rexx/HRBSUTIL.rexx 'HRBS.REXX(HRBSUTIL)'
```

### Step 2.5: Upload 80-Byte Sequential Data Files
```text
quote site recfm=fb lrecl=80 blksize=0 tracks primary=5 secondary=5
put data/RESERV.dat     'HRBS.RESERV.INPUT'
put data/FILE1.dat      'HRBS.FILE1'
put data/FILE2.dat      'HRBS.FILE2'
put data/TRANS.dat      'HRBS.TRANS.INPUT'
put data/SERVICE.dat    'HRBS.SERVICE.INPUT'
put data/RESERV_BAD.dat 'HRBS.RESERV.BAD'
```

### Step 2.6: Upload 100-Byte Invoice Data File
```text
quote site recfm=fb lrecl=100 blksize=0 tracks primary=5 secondary=5
put data/INVOICE.dat    'HRBS.INVOICE.INPUT'
```

---

## 3. Submitting JCL Directly via FTP (JES Interface)

You can submit jobs directly from your workstation to the z/OS JES reader:

```text
quote site filetype=jes
put jcl/LOADDATA.jcl
put jcl/JOB01_SORT_DEDUP.jcl
put jcl/JOB02_COBOL_MATCH.jcl
put jcl/JOB03_REXX_DEDUP_SORT.jcl
put jcl/JOB04_PASS_COPY_SORT_DESC.jcl
put jcl/JOB07_VALIDATE.jcl
put jcl/JOB08_VSAM_DEF_LOAD.jcl
put jcl/JOB09_VSAM_UPDATE.jcl
put jcl/JOB06_COBOL_BILL.jcl
put jcl/JOB11_REPORT.jcl
put jcl/JOB10_HRBS_BATCH_CYCLE.jcl
```

When `filetype=jes` is active, the FTP server returns the JES Job ID (e.g., `JOB00123`) and logs execution status.

---

## 4. One-Click FTP Batch Script (`tools/upload.bat`)

To automate the entire upload process, create `tools/ftp_commands.txt`:

```text
open mainframe.college.edu
MYUSER
MYPASS
ascii
quote site recfm=fb lrecl=80 blksize=0
put cobol/HRBSMTCH.cbl 'HRBS.COBOL(HRBSMTCH)'
put cobol/HRBSBIL.cbl  'HRBS.COBOL(HRBSBIL)'
put cobol/HRBSVAL.cbl  'HRBS.COBOL(HRBSVAL)'
put cobol/HRBSUPD.cbl  'HRBS.COBOL(HRBSUPD)'
put cobol/HRBSRPT.cbl  'HRBS.COBOL(HRBSRPT)'
put cobol/HRBSDB2.cbl  'HRBS.COBOL(HRBSDB2)'
put rexx/HRBSDEDP.rexx 'HRBS.REXX(HRBSDEDP)'
put rexx/HRBSUTIL.rexx 'HRBS.REXX(HRBSUTIL)'
quote site recfm=fb lrecl=80 blksize=0 tracks primary=5 secondary=5
put data/RESERV.dat    'HRBS.RESERV.INPUT'
put data/FILE1.dat     'HRBS.FILE1'
put data/FILE2.dat     'HRBS.FILE2'
put data/TRANS.dat     'HRBS.TRANS.INPUT'
put data/SERVICE.dat   'HRBS.SERVICE.INPUT'
quote site recfm=fb lrecl=100 blksize=0 tracks primary=5 secondary=5
put data/INVOICE.dat   'HRBS.INVOICE.INPUT'
quit
```

Run:
```cmd
ftp -s:tools/ftp_commands.txt
```
