# HRBS - Project Changelog & Phase 1 Hardening Record

This document records all defects, architectural discrepancies, syntax fixes, and functional extensions implemented to complete the **Hotel Reservation and Billing System (HRBS)** mainframe project.

---

## 1. Phase 1 Review & Hardening Fixes

### A. ICETOOL Count Semantics in Assignment 4
- **Files Modified:** [jcl/JOB04_PASS_COPY_SORT_DESC.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB04_PASS_COPY_SORT_DESC.jcl) and [jcl/JOB04_FAIL_COPY_SORT_DESC.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB04_FAIL_COPY_SORT_DESC.jcl)
- **Defect:** Phase 1 originally specified `COUNT FROM(CMP) EQUAL(1) RC4`. In IBM DFSORT/ICETOOL, `EQUAL(1) RC4` sets return code 4 when the condition IS met (i.e. when count = 1). In the PASS scenario where counts are equal, `&&CMP` contains 1 unique record, which caused ICETOOL to return RC 4 instead of RC 0!
- **Fix:** Corrected control card to `COUNT FROM(CMP) NOTEQUAL(1) RC4`.
  - When counts match (count = 1), `NOTEQUAL(1)` is FALSE $\rightarrow$ ICETOOL sets `RC = 0`. The `IF (CHECK.RC = 0) THEN` branch executes, catalogs `&SYSUID..HRBS.A4.OUTPUT`, and finishes with **CC 0000**.
  - When counts differ (count = 2, simulated via `STOPAFT=90`), `NOTEQUAL(1)` is TRUE $\rightarrow$ ICETOOL sets `RC = 4`. The `ELSE` branch executes, outputs error message, sets `IDCAMS MAXCC=8`, discards the output dataset, and finishes with deliberate **CC 0008**.
- **Rerunnability:** Verified `//DEL EXEC PGM=IEFBR14` with `DISP=(MOD,DELETE)` on `&SYSUID..HRBS.A4.OUTPUT` at the beginning of both jobs.

### B. Guest ID Layout Inconsistency in Billing Module
- **File Modified:** [cobol/HRBSBIL.cbl](file:///e:/mainframe%20project%20sem%201/hrbs/cobol/HRBSBIL.cbl)
- **Defect:** `INV-GUEST` was defined as `PIC X(10)`, but string construction used `'G'` + 6 digits (`WS-SEQ`), resulting in a 7-character value with unformatted spaces. [docs/PROJECT_CONTEXT.md](file:///e:/mainframe%20project%20sem%201/hrbs/docs/PROJECT_CONTEXT.md) and [data/INVOICE.dat](file:///e:/mainframe%20project%20sem%201/hrbs/data/INVOICE.dat) require `'G'` followed by 9 numeric digits (`G000000001`).
- **Fix:** Updated `WS-GUEST-SEQ` to `PIC 9(09)` and formatted `INV-GUEST` as `STRING 'G' WS-GUEST-SEQ DELIMITED BY SIZE INTO INV-GUEST`.

### C. Hardcoded Tax Rates & Service Charges in HRBSBIL
- **File Modified:** [cobol/HRBSBIL.cbl](file:///e:/mainframe%20project%20sem%201/hrbs/cobol/HRBSBIL.cbl)
- **Fix:** Encapsulated business policy variables into a structured parameter record in `WORKING-STORAGE SECTION`:
  ```cobol
       01  WS-BILLING-PARAMETERS.
           05  PARM-BASE-SVC-RATE   PIC 9V99 VALUE 0.05.
           05  PARM-GST-SLAB-LIMIT  PIC 9(06) VALUE 7500.
           05  PARM-GST-LOW-RATE    PIC 9V99 VALUE 0.05.
           05  PARM-GST-HIGH-RATE   PIC 9V99 VALUE 0.18.
  ```

### D. TSO/E REXX EXECIO Return Code Handling
- **File Modified:** [rexx/HRBSDEDP.rexx](file:///e:/mainframe%20project%20sem%201/hrbs/rexx/HRBSDEDP.rexx)
- **Defect:** REXX checked `if rc <> 0 then do ... exit 8`. On IBM z/OS TSO/E, `EXECIO * DISKR` returns `RC = 2` upon reaching End-Of-File (EOF) during normal read operations. A strict `rc <> 0` test causes false aborts on z/OS.
- **Fix:** Updated condition to `if read_rc <> 0 & read_rc <> 2 then do ... exit 8`.

### E. Missing Billing Execution JCL
- **File Created:** [jcl/JOB06_COBOL_BILL.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB06_COBOL_BILL.jcl)
- **Implementation:** Added full compile, link-edit, delete, and execution JCL following the standardized `IGYWCL` structure established in JOB02.

---

## 2. Phase 2 New Components Implemented

| Component | File | Type | Description |
|---|---|---|---|
| **HRBSVAL** | [cobol/HRBSVAL.cbl](file:///e:/mainframe%20project%20sem%201/hrbs/cobol/HRBSVAL.cbl) | COBOL | Validates sorted reservations across 10 rules. Outputs VALID (80 B) and REJECT (120 B) datasets. Sets RC 0 (no rejects) or RC 4 (rejects). |
| **JOB07** | [jcl/JOB07_VALIDATE.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB07_VALIDATE.jcl) | JCL | Compiles, link-edits, and executes HRBSVAL. |
| **JOB08** | [jcl/JOB08_VSAM_DEF_LOAD.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB08_VSAM_DEF_LOAD.jcl) | JCL | IDCAMS job defining KSDS cluster (KEY 8 at offset 12, RECLEN 80) and initial REPRO with rerun handling. |
| **HRBSUPD** | [cobol/HRBSUPD.cbl](file:///e:/mainframe%20project%20sem%201/hrbs/cobol/HRBSUPD.cbl) | COBOL | VSAM KSDS transaction engine. Applies ADD, CANCEL, CHECK-OUT, and UPDATE with random I-O and in-memory room-availability overlap detection. |
| **JOB09** | [jcl/JOB09_VSAM_UPDATE.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB09_VSAM_UPDATE.jcl) | JCL | Compiles, link-edits, and executes HRBSUPD against KSDS master. |
| **SERVICE.dat** | [data/SERVICE.dat](file:///e:/mainframe%20project%20sem%201/hrbs/data/SERVICE.dat) | Data | 80-byte extra-service charges (Dining, Laundry, Spa, Mini-bar, Cab). |
| **TRANS.dat** | [data/TRANS.dat](file:///e:/mainframe%20project%20sem%201/hrbs/data/TRANS.dat) | Data | 31 transactions including deliberate errors (duplicates, overlap, not found, invalid action). |
| **HRBSBIL Ext.** | [cobol/HRBSBIL.cbl](file:///e:/mainframe%20project%20sem%201/hrbs/cobol/HRBSBIL.cbl) | COBOL | Extended to bill status 'C' and 'O', and dynamically load extra charges from optional SERVICE file. |
| **HRBSRPT** | [cobol/HRBSRPT.cbl](file:///e:/mainframe%20project%20sem%201/hrbs/cobol/HRBSRPT.cbl) | COBOL | 132-column formatted Billing Report with page numbering, 55-line pagination, room-type subtotals, and grand totals. |
| **JOB11** | [jcl/JOB11_REPORT.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB11_REPORT.jcl) | JCL | DFSORT sort step and HRBSRPT report execution. |
| **DCLGENs** | [cobol/dclgen/](file:///e:/mainframe%20project%20sem%201/hrbs/cobol/dclgen/) | Copybook | Table declarations for GUEST, ROOM, RESERVATION, BILL, and PAYMENT. |
| **HRBSDB2** | [cobol/HRBSDB2.cbl](file:///e:/mainframe%20project%20sem%201/hrbs/cobol/HRBSDB2.cbl) | COBOL | Embedded SQL batch program. Loads reservations/bills, handles duplicate keys (-803), commits every 25 rows, and queries unpaid bills via cursor. |
| **JOB12** | [jcl/JOB12_DB2_LOAD_REPORT.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB12_DB2_LOAD_REPORT.jcl) | JCL | Precompiles, compiles, links, binds package/plan, and runs HRBSDB2. Fully parameterized via JCL SET block. |
| **HRBSUTIL** | [rexx/HRBSUTIL.rexx](file:///e:/mainframe%20project%20sem%201/hrbs/rexx/HRBSUTIL.rexx) | REXX | TSO/ISPF utility for dataset record counting (COUNT), key duplicate auditing (CHKDUP), and reservation query (FIND). |
| **JOB10** | [jcl/JOB10_HRBS_BATCH_CYCLE.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB10_HRBS_BATCH_CYCLE.jcl) | JCL | Master end-to-end batch cycle orchestrating all 9 steps with GDG allocation, COND return code policy, and restart points. |
| **LOADDATA** | [jcl/LOADDATA.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/LOADDATA.jcl) | JCL | Generated in-stream IEBGENER job allocating and loading all 7 input datasets with a single submission. |
| **Tools** | [tools/](file:///e:/mainframe%20project%20sem%201/hrbs/tools/) | Python | `check_sources.py`, `make_load_jobs.py`, and `reference_runner.py`. |
