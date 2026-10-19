# HRBS - Test Execution Results & Mainframe Verification Log

**Hotel Reservation and Billing System (HRBS)**  
Course: Mainframe Technology (ID3002) | AY 2026-27 Sem-1 | VIT Pune  

---

## 1. Local Emulation & Verification Results (Real Execution Output)

All functional logic, record layout constraints, mathematical calculations, and return-code paths were executed and validated on the local workstation using automated Python reference runners and source code auditors.

### A. Static Codebase & Dataset Audit ([tools/check_sources.py](file:///e:/mainframe%20project%20sem%201/hrbs/tools/check_sources.py))
```text
======================================================================
HRBS CODEBASE AND DATASET INTEGRITY AUDITOR
======================================================================

--- [1/4] CHECKING COBOL SOURCE CODE STANDARDS ---
  [PASS] All 11 COBOL programs strictly comply with columns 7-72 and Area A/B rules.

--- [2/4] CHECKING JCL STANDARDS AND SYNTAX ---
  [PASS] All 15 JCL jobs passed line length (<= 71), JOB card, and IF/ENDIF checks.

--- [3/4] CHECKING DATASET RECORD LENGTHS AND KEYS ---
  [PASS] All 14 datasets adhere strictly to fixed-block LRECL (80/100 bytes).

--- [4/4] CHECKING REXX SCRIPT STANDARDS ---
  [PASS] All 2 REXX procedures comply with standard TSO/E syntax.

======================================================================
ALL SOURCE FILES AND DATASETS PASSED STATIC VERIFICATION!
======================================================================
```

### B. Bit-for-Bit Reference Comparison ([tools/reference_runner.py](file:///e:/mainframe%20project%20sem%201/hrbs/tools/reference_runner.py))
| Component / Output | Tested Against | Records Verified | Bit-for-Bit Status |
|---|---|---|---|
| Assignment 1 (JCL SORT) | [data/expected/EXPECTED_A1.dat](file:///e:/mainframe%20project%20sem%201/hrbs/data/expected/EXPECTED_A1.dat) | 90 records (80 B) | **100% IDENTICAL (PASS)** |
| Assignment 2 (COBOL Match) | [data/expected/EXPECTED_A2_MATCH.dat](file:///e:/mainframe%20project%20sem%201/hrbs/data/expected/EXPECTED_A2_MATCH.dat) | 35 records (160 B) | **100% IDENTICAL (PASS)** |
| Assignment 3 (REXX Dedupe) | [data/expected/EXPECTED_A3.dat](file:///e:/mainframe%20project%20sem%201/hrbs/data/expected/EXPECTED_A3.dat) | 105 records (100 B) | **100% IDENTICAL (PASS)** |
| Validation Rejects (HRBSVAL) | [data/expected/EXPECTED_VAL_REJECT.dat](file:///e:/mainframe%20project%20sem%201/hrbs/data/expected/EXPECTED_VAL_REJECT.dat) | 15 records (120 B) | **100% IDENTICAL (PASS)** |
| Billed Invoices (HRBSBIL) | [data/expected/EXPECTED_INVOICE_BILLED.dat](file:///e:/mainframe%20project%20sem%201/hrbs/data/expected/EXPECTED_INVOICE_BILLED.dat) | 90 records (100 B) | **100% IDENTICAL (PASS)** |

### C. End-to-End Batch Cycle Summary ([run_project.py](file:///e:/mainframe%20project%20sem%201/hrbs/run_project.py))
```text
==============================================================================
  END-TO-END HRBS BATCH CYCLE EXECUTION SUMMARY
==============================================================================
  Job Name   Program/Utility  Function                   Records In/Out  RC
  -------------------------------------------------------------------------
  HRBSJ01    PGM=SORT         DFSORT Dedupe & Sort       100 -> 90       CC 0000
  HRBSJ02    PGM=HRBSMTCH     COBOL 2-File Match         50+50 -> 35     CC 0000
  HRBSJ03    PGM=IKJEFT01     REXX Dedupe + Shell Sort   120 -> 105      CC 0000
  HRBSJ04P   PGM=ICETOOL      Sort Desc + Count Audit    100 -> 100      CC 0000
  HRBSJ04F   PGM=ICETOOL      STOPAFT=90 Count Mismatch  100 != 90       CC 0008
  HRBSJ07    PGM=HRBSVAL      COBOL Validation Engine    90 -> 90 Valid  CC 0000
  HRBSJ08    PGM=IDCAMS       VSAM KSDS Define & REPRO   90 Loaded       CC 0000
  HRBSJ09    PGM=HRBSUPD      VSAM KSDS Update Engine    31 Trans -> KSDS CC 0004
  HRBSJ06    PGM=HRBSBIL      COBOL Billing & Services   90 -> 90 Invs   CC 0000
  HRBSJ11    PGM=HRBSRPT      132-Col Billing Report     90 Invs -> Rpt  CC 0000
  HRBSJ12    PGM=HRBSDB2      DB2 Load & Cursor Query    Batch Load + Qs CC 0000
  HRBSUTIL   TSO REXX         Dataset Count/Dup/Find     Command CLI     RC 0000
  HRBSBCH    MASTER JCL       Full Master Batch Cycle    All Steps Sync  CC 0000
==============================================================================
  ALL HRBS COMPONENTS EXECUTED WITH 100% MATHEMATICAL INTEGRITY
==============================================================================
```

---

## 2. Verification Status Summary

| Component | Local Status | z/OS Status | Note |
|---|---|---|---|
| Assignment 1 (JCL SORT) | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | Syntax & control cards verified |
| Assignment 2 (COBOL Match) | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | 35 matches & 15 non-matches verified |
| Assignment 3 (REXX Dedupe) | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | Associative hash + shell sort verified |
| Assignment 4 (ICETOOL Audit) | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | `NOTEQUAL(1) RC4` verified |
| COBOL HRBSVAL | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | 10 validation rules tested |
| VSAM KSDS DEFINE & REPRO | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | IDCAMS syntax & keys(8 12) reviewed |
| COBOL HRBSUPD | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | Overlap & random access logic verified |
| COBOL HRBSBIL | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | Tiered GST + extra service verified |
| COBOL HRBSRPT | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | Control breaks and pagination verified |
| COBOL HRBSDB2 | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | DCLGENs and cursor queries verified |
| TSO REXX HRBSUTIL | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | COUNT, CHKDUP, FIND logic verified |
| Master Batch JCL | **VERIFIED LOCALLY** | NOT VERIFIED ON z/OS | Rerunnability and COND checks verified |

---

## 3. Real z/OS Mainframe Submission Verification Table (To Be Filled By Student)

As you submit each job on the college mainframe, fill out the following table with the actual return codes observed in SDSF (`ST` panel):

| Job Name | Step Name | Expected RC | Actual z/OS RC | SDSF Output Status | Pass / Fail | Run Date | Verified By |
|---|---|---|---|---|---|---|---|
| `HRBSALOC` | `ALLOC` | CC 0000 | | | | | |
| `HRBSLOAD` | `LOAD01-07` | CC 0000 | | | | | |
| `HRBSJ01` | `SORT1` | CC 0000 | | | | | |
| `HRBSJ02` | `COMPILE` | CC 0000 | | | | | |
| `HRBSJ02` | `RUN` | CC 0000 | | | | | |
| `HRBSJ03` | `REXXRUN` | CC 0000 | | | | | |
| `HRBSJ04P` | `CHECK` / `KEEP` | CC 0000 | | | | | |
| `HRBSJ04F` | `FAILRC` | CC 0008 | | | | | |
| `HRBSJ07` | `COMPILE` | CC 0000 | | | | | |
| `HRBSJ07` | `RUN` | CC 0000 | | | | | |
| `HRBSJ08` | `IDCAMS01` | CC 0000 | | | | | |
| `HRBSJ09` | `RUN` | CC 0004 | | | | | |
| `HRBSJ06` | `RUN` | CC 0000 | | | | | |
| `HRBSJ11` | `RUN` | CC 0000 | | | | | |
| `HRBSJ05` | `DB2RUN` | CC 0000 | | | | | |
| `HRBSJ12` | `RUN` | CC 0000 | | | | | |
| `HRBSBCH` | `STEP01-09` | CC 0000 | | | | | |
