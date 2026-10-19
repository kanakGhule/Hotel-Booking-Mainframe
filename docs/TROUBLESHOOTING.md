# HRBS - Mainframe Troubleshooting & Problem Resolution Guide

This guide details common z/OS system abends, JCL errors, COBOL file status codes, and DB2 SQLCODEs encountered during the development and execution of the **Hotel Reservation and Billing System (HRBS)**, along with precise diagnostic steps and remedies.

---

## 1. System ABENDs

### S0C7 — Data Exception
- **Symptom:** Program terminates abnormally with completion code `S0C7` in `JESMSGLG`.
- **Cause:** A computational instruction attempted arithmetic on a zoned decimal (`PIC 9`) or packed decimal (`COMP-3`) field that contains non-numeric data (such as uninitialized spaces `X'40'` or alpha characters).
- **In HRBS:** Common when reading unformatted test data or when dates/rates contain blanks.
- **Fix:**
  1. Inspect input datasets in ISPF edit mode with `HEX ON`.
  2. Verify that rate (`cols 67-72`) and guest count (`cols 65-66`) contain valid numeric digits (`F0`-`F9` in EBCDIC).
  3. Ensure `INITIALIZE` or `MOVE ZERO` is executed on all accumulators in `WORKING-STORAGE` before calculation.
  4. Ensure [cobol/HRBSVAL.cbl](file:///e:/mainframe%20project%20sem%201/hrbs/cobol/HRBSVAL.cbl) filters invalid records before passing data to billing.

### S806 — Module Not Found
- **Symptom:** Job fails immediately with `CSV003I REQUESTED MODULE <name> NOT FOUND`.
- **Cause:** The execution step attempted to load a program not present in `STEPLIB`, `JOBLIB`, or the system LNKLST.
- **Fix:**
  1. Check the compile step in the same job: Did `COMPILE.COBOL` complete with RC 0 or 4? If the compile failed (RC 8 or 12), the link-edit step never generated the load module in `<userid>.HRBS.LOAD`.
  2. Verify that the `STEPLIB DD` points to the correct load library:
     ```jcl
     //STEPLIB DD DISP=SHR,DSN=&SYSUID..HRBS.LOAD
     ```
  3. Verify member existence using ISPF 3.4 on `<userid>.HRBS.LOAD`.

### S013 — Open Failure / DCB Conflict
- **Symptom:** Step fails with `IEC141I 013-18` or `IEC141I 013-20`.
- **Cause:** Conflict between the dataset's cataloged attributes and the JCL DD or COBOL `FD` specifications (e.g. trying to open an 80-byte dataset with LRECL 100).
- **Fix:**
  1. Check the dataset's record format and logical record length via ISPF 3.2.
  2. Confirm `FD` record description matches actual dataset:
     - `RESERV`, `FILE1`, `FILE2`, `TRANS`, `SERVICE`: `RECFM=FB`, `LRECL=80`.
     - `INVOICE`: `RECFM=FB`, `LRECL=100`.
     - `REJECT`, `AUDIT`: `RECFM=FB`, `LRECL=120`.
     - `REPORT`: `RECFM=FB`, `LRECL=132`.

### SB37 / SD37 / SE37 — Out of Space
- **Symptom:** Step terminates with `IEC030I B37-04` or `D37-04`.
- **Cause:** The primary and secondary space allocations on the disk volume were exhausted during output writing.
- **Fix:**
  1. Increase the space allocation in JCL:
     ```jcl
     SPACE=(TRK,(10,10),RLSE)
     ```
  2. Add `RLSE` to release unused space after completion.

---

## 2. JCL Syntax & Allocation Errors

| Error Message | Meaning | Solution |
|---|---|---|
| `IEF212I DATA SET NOT FOUND` | Referenced input dataset does not exist in catalog | Submit [jcl/LOADDATA.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/LOADDATA.jcl) or verify dataset name spelling in ISPF 3.4 |
| `IEF287I NOT CATLGD 2` | Dataset name already exists in catalog | Ensure the cleanup step `//DEL EXEC PGM=IEFBR14` with `DISP=(MOD,DELETE)` runs before creating the new dataset |
| `JCL ERROR - LINE EXCEEDS 71` | JCL statement extends into column 72 | Wrap parameters onto a continuation line starting with `//` in cols 1-2 followed by a space |
| `IEF605I UNIDENTIFIED OPERATION` | Typo in JCL verb or invalid spacing | Ensure valid spacing: `//STEPNAME EXEC PGM=...` with single space delimiters |

---

## 3. COBOL File Status Codes

When a COBOL I/O statement fails, check the two-byte `FILE STATUS` variable displayed in `SYSOUT`:

| Status Code | Meaning | Occurs In | Resolution |
|---|---|---|---|
| **`00`** | Successful completion | All programs | Normal operation |
| **`05`** | Optional file not present on OPEN | `HRBSBIL` (`SRVFILE`) | Normal for optional files; treated as 0 extra charges |
| **`10`** | End of file reached | `HRBSMTCH`, `HRBSBIL`, `HRBSVAL` | Normal EOF condition; set loop termination flag |
| **`22`** | Duplicate key on WRITE | `HRBSUPD` (VSAM KSDS) | Key already exists in master; write to `REJOUT` with reason '22' |
| **`23`** | Key not found | `HRBSUPD` (VSAM KSDS) | Record ID does not exist for Cancel/Checkout; write to `REJOUT` |
| **`35`** | File not found on OPEN INPUT | All programs | Verify dataset is allocated and populated before running job |
| **`37`** | Open mode invalid | All programs | Check `OPEN INPUT` vs `OPEN OUTPUT` vs `OPEN I-O` permissions |
| **`92`** | Logic error / file not open | All programs | Ensure `OPEN` was executed and status checked before `READ` / `WRITE` |

---

## 4. DB2 SQLCODEs

During DB2 batch load or queries in [cobol/HRBSDB2.cbl](file:///e:/mainframe%20project%20sem%201/hrbs/cobol/HRBSDB2.cbl) or [jcl/JOB05_DB2_SCHEMA.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB05_DB2_SCHEMA.jcl):

### SQLCODE = 0
Normal successful execution of the SQL statement.

### SQLCODE = +100
No rows found matching the search condition, or end of cursor reached during `FETCH`. Normal loop termination condition.

### SQLCODE = -204 (Object Not Defined)
- **Cause:** Table or view name not found in the DB2 catalog.
- **Fix:** Check table schema prefix: Ensure tables are created under `HRBS` (e.g. `HRBS.RESERVATION`). Run [db2/SCHEMA.sql](file:///e:/mainframe%20project%20sem%201/hrbs/db2/SCHEMA.sql) through [jcl/JOB05_DB2_SCHEMA.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB05_DB2_SCHEMA.jcl) first.

### SQLCODE = -551 (Authorization Failure)
- **Cause:** The user ID does not have `SELECT`, `INSERT`, or `BIND` privileges on the target table/plan.
- **Fix:** Request `GRANT ALL ON HRBS.* TO <userid>` from your DB2 DBA.

### SQLCODE = -803 (Duplicate Key Violation)
- **Cause:** Attempted to insert a row with a primary key that already exists in a unique index.
- **Fix:** In `HRBSDB2`, this is handled gracefully:
  ```cobol
  IF SQLCODE = -803
      ADD 1 TO WS-RESV-DUP-CNT
      DISPLAY 'DUPLICATE RECORD IGNORED: ' HV-RES-ID
  ```
  The job continues without aborting.

### SQLCODE = -805 (DBRM / Package Not Found)
- **Cause:** Plan was not bound with the corresponding package collection or member timestamp mismatch between precompile and bind.
- **Fix:** Re-run Step 2 (`BIND PACKAGE` and `BIND PLAN`) in [jcl/JOB12_DB2_LOAD_REPORT.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB12_DB2_LOAD_REPORT.jcl) to sync the precompiler timestamp token.

---

## 5. DFSORT & ICETOOL Return Code Semantics

### ICETOOL COUNT Operator
In [jcl/JOB04_PASS_COPY_SORT_DESC.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB04_PASS_COPY_SORT_DESC.jcl), we use:
```jcl
//CHECK    EXEC PGM=ICETOOL
//TOOLIN   DD *
  COUNT FROM(CMP) NOTEQUAL(1) RC4
/*
```
- **Rule:** ICETOOL evaluates the condition. If the condition IS TRUE, it returns the specified code (`RC4`). If the condition IS FALSE, it returns `RC = 0`.
- **In PASS:** The two record counts are identical $\rightarrow$ `&&CMP` has 1 record $\rightarrow$ `NOTEQUAL(1)` is FALSE $\rightarrow$ ICETOOL returns `RC = 0`.
- **In FAIL:** The counts differ ($100 \neq 90$) $\rightarrow$ `&&CMP` has 2 records $\rightarrow$ `NOTEQUAL(1)` is TRUE $\rightarrow$ ICETOOL returns `RC = 4`, triggering the `ELSE` branch in JCL.
