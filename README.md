# Hotel Reservation and Billing System (HRBS)

**Enterprise Batch Mainframe Application**  
**Course:** Mainframe Technology (ID3002) (PEC-I), AY 2026-27 Sem-1  
**Institute:** BRACT's Vishwakarma Institute of Technology (VIT), Pune  
**Department:** Computer Engineering | **Mentor:** Mrs. Madhura Sanap  

---

## Folder Map

```text
hrbs/
├── README.md                          # Project overview and quick start guide
├── run_project.py                     # Local 12-component emulation and verification runner
├── cobol/                             # Enterprise COBOL programs and table copybooks
│   ├── HRBSMTCH.cbl                   # Assignment 2: Two-file table match (160 B output)
│   ├── HRBSBIL.cbl                    # Billing engine (status C/O, 5% svc, GST slabs, extra charges)
│   ├── HRBSVAL.cbl                    # Reservation validation engine (10 business rules, 120 B rejects)
│   ├── HRBSUPD.cbl                    # VSAM KSDS random update engine (Add/Cancel/Checkout/Update)
│   ├── HRBSRPT.cbl                    # Formatted 132-column billing report with control breaks
│   ├── HRBSDB2.cbl                    # DB2 embedded SQL batch loader and unpaid bills cursor query
│   └── dclgen/                        # DB2 DCLGEN copybooks
│       ├── DCLGUEST.cbl               # Table declaration for HRBS.GUEST
│       ├── DCLROOM.cbl                # Table declaration for HRBS.ROOM
│       ├── DCLRESV.cbl                # Table declaration for HRBS.RESERVATION
│       ├── DCLBILL.cbl                # Table declaration for HRBS.BILL
│       └── DCLPAY.cbl                 # Table declaration for HRBS.PAYMENT
├── jcl/                               # Production z/OS JCL job streams
│   ├── ALLOCATE.jcl                   # Initial allocation of PS datasets and PDS libraries
│   ├── LOADDATA.jcl                   # In-stream IEBGENER job loading all 7 input datasets
│   ├── JOB01_SORT_DEDUP.jcl           # Assignment 1: DFSORT deduplication and ascending sort
│   ├── JOB02_COBOL_MATCH.jcl          # Assignment 2: Compile, link-edit and run HRBSMTCH
│   ├── JOB03_REXX_DEDUP_SORT.jcl      # Assignment 3: Run REXX HRBSDEDP in batch (IKJEFT01)
│   ├── JOB04_PASS_COPY_SORT_DESC.jcl  # Assignment 4: Count reconciliation audit (PASS, CC 0000)
│   ├── JOB04_FAIL_COPY_SORT_DESC.jcl  # Assignment 4: Count mismatch simulation (FAIL, CC 0008)
│   ├── JOB05_DB2_SCHEMA.jcl           # DSNTEP2 job running DB2 DDL and initial seed inserts
│   ├── JOB06_COBOL_BILL.jcl           # Compile, link-edit and run HRBSBIL billing engine
│   ├── JOB07_VALIDATE.jcl             # Compile, link-edit and run HRBSVAL validation engine
│   ├── JOB08_VSAM_DEF_LOAD.jcl        # IDCAMS DEFINE CLUSTER KSDS and initial REPRO load
│   ├── JOB09_VSAM_UPDATE.jcl          # Compile, link-edit and run HRBSUPD transaction engine
│   ├── JOB10_HRBS_BATCH_CYCLE.jcl     # Master end-to-end batch cycle with GDG and COND checks
│   ├── JOB11_REPORT.jcl               # DFSORT sort and HRBSRPT 132-column report execution
│   └── JOB12_DB2_LOAD_REPORT.jcl      # DB2 precompile, compile, bind, and run HRBSDB2
├── rexx/                              # TSO/E REXX procedures
│   ├── HRBSDEDP.rexx                  # Assignment 3: Invoice deduplication and shell sort
│   └── HRBSUTIL.rexx                  # Command-line utility for COUNT, CHKDUP, and FIND
├── data/                              # Test datasets and verified reference baselines
│   ├── RESERV.dat                     # Baseline reservations (100 records x 80 B, 10 dups)
│   ├── FILE1.dat                      # Assignment 2 reservations (50 records x 80 B)
│   ├── FILE2.dat                      # Assignment 2 payments (50 records x 80 B)
│   ├── INVOICE.dat                    # Baseline invoices (120 records x 100 B, 15 dups)
│   ├── TRANS.dat                      # VSAM transactions (31 records x 80 B, deliberate errors)
│   ├── SERVICE.dat                    # Extra services (10 records x 80 B)
│   ├── RESERV_BAD.dat                 # Negative test records testing 10 validation rules
│   ├── EMPTY.dat, SINGLE_REC.dat      # Boundary edge-case datasets
│   ├── MAX_LEN_NAMES.dat              # Maximum 20-character guest name records
│   ├── PAY_MISMATCH.dat               # Unpaid/underpaid payment records
│   └── expected/                      # Verified expected outputs for all components
├── db2/                               # Relational database schema and SQL scripts
│   ├── SCHEMA.sql                     # Table DDL (GUEST, ROOM, RESERVATION, BILL, PAYMENT) & seed
│   └── QUERIES.sql                    # Analytical reporting queries (revenue, unpaid, occupancy)
├── docs/                              # Technical documentation and guides
│   ├── ARCHITECTURE.md                # System architecture, Mermaid data flow, and record layouts
│   ├── RUNBOOK.md                     # Step-by-step z/OS execution runbook and screenshot checklist
│   ├── CONFIG.md                      # Site-specific configuration variables (User ID, DB2 SSID)
│   ├── TROUBLESHOOTING.md             # Resolution guide for S0C7, S806, S013, file status & SQLCODEs
│   ├── TEST_PLAN.md                   # Comprehensive test matrix covering 33 test cases
│   ├── TEST_RESULTS.md                # Local execution results and blank z/OS submission table
│   ├── CHANGELOG.md                   # Complete record of Phase 1 fixes and Phase 2 enhancements
│   ├── FTP_UPLOAD.md                  # Exact FTP instructions for transferring files to z/OS
│   └── PROJECT_CONTEXT.md             # Domain background, business requirements, and slide plan
└── tools/                             # Automation and verification utilities
    ├── check_sources.py               # Automated auditor for COBOL, JCL, data, and REXX standards
    ├── make_load_jobs.py              # Generator for jcl/LOADDATA.jcl in-stream loader
    └── reference_runner.py            # Reference runner computing expected outputs in data/expected/
```

---

## Quick Start (8 Steps to Complete Execution)

1. **Audit Code Standards:**
   ```powershell
   python tools/check_sources.py
   ```
   *Verifies COBOL columns 7–72, JCL lines $\le 71$, and exact fixed-block dataset lengths.*

2. **Run Local Emulation Suite:**
   ```powershell
   python run_project.py
   ```
   *Executes all 12 components locally and confirms 100% bit-for-bit mathematical integrity.*

3. **Configure Your Site Settings:**
   Review [docs/CONFIG.md](file:///e:/mainframe%20project%20sem%201/hrbs/docs/CONFIG.md). Update `&SYSUID` and `DB2SSID` if your lab uses specific qualifiers.

4. **Allocate z/OS Libraries:**
   Submit [jcl/ALLOCATE.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/ALLOCATE.jcl) via ISPF or FTP (`CC 0000`).

5. **Load Test Datasets:**
   Submit [jcl/LOADDATA.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/LOADDATA.jcl) to populate all input files in one step (`CC 0000`).

6. **Deploy DB2 Relational Schema:**
   Submit [jcl/JOB05_DB2_SCHEMA.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB05_DB2_SCHEMA.jcl) to build tables and indexes (`CC 0000`).

7. **Execute Mandatory Assignments:**
   Submit [jcl/JOB01_SORT_DEDUP.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB01_SORT_DEDUP.jcl) through [jcl/JOB04_PASS_COPY_SORT_DESC.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB04_PASS_COPY_SORT_DESC.jcl) and verify `CC 0000` (`CC 0008` for FAIL).

8. **Execute Master Batch Pipeline:**
   Submit [jcl/JOB10_HRBS_BATCH_CYCLE.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB10_HRBS_BATCH_CYCLE.jcl) to run the complete end-to-end batch cycle (`CC 0000`).
