# HRBS - Mainframe Execution Runbook & Operational Guide

This runbook outlines the exact step-by-step submission sequence on IBM z/OS (ISPF / SDSF) with expected return codes, dataset verification instructions, and a screenshot capture checklist for project presentation and viva examination.

---

## 1. End-to-End Execution Sequence on z/OS

Submit the jobs in the following order:

| Step | Job Name | JCL File | Description | Expected RC | Key Output Dataset / Verification |
|---|---|---|---|---|---|
| **01** | `HRBSALOC` | [ALLOCATE.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/ALLOCATE.jcl) | Dataset Allocation | **CC 0000** | Allocates all PS and PDS libraries |
| **02** | `HRBSLOAD` | [LOADDATA.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/LOADDATA.jcl) | In-stream Data Load | **CC 0000** | Populates input files via IEBGENER |
| **03** | `HRBSJ01` | [JOB01_SORT_DEDUP.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB01_SORT_DEDUP.jcl) | DFSORT Dedupe & Sort | **CC 0000** | `RESERV.SORTED` (90 records, ascending) |
| **04** | `HRBSJ02` | [JOB02_COBOL_MATCH.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB02_COBOL_MATCH.jcl) | COBOL File Match | **CC 0000** | `FILE3` (35 matched records, 160 B) |
| **05** | `HRBSJ03` | [JOB03_REXX_DEDUP_SORT.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB03_REXX_DEDUP_SORT.jcl) | REXX Dedupe & Shell Sort | **CC 0000** | `INVOICE.CLEAN` (105 records) |
| **06** | `HRBSJ04P` | [JOB04_PASS_COPY_SORT_DESC.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB04_PASS_COPY_SORT_DESC.jcl) | Count Audit (PASS) | **CC 0000** | `A4.OUTPUT` kept (100 records) |
| **07** | `HRBSJ04F` | [JOB04_FAIL_COPY_SORT_DESC.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB04_FAIL_COPY_SORT_DESC.jcl) | Count Audit (FAIL) | **CC 0008** | Error printed, output discarded |
| **08** | `HRBSJ07` | [JOB07_VALIDATE.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB07_VALIDATE.jcl) | Reservation Validation | **CC 0000** | `RESERV.VALID` (90 valid records) |
| **09** | `HRBSJ08` | [JOB08_VSAM_DEF_LOAD.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB08_VSAM_DEF_LOAD.jcl) | VSAM KSDS Define/Load | **CC 0000** | `RESERV.KSDS` loaded via REPRO |
| **10** | `HRBSJ09` | [JOB09_VSAM_UPDATE.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB09_VSAM_UPDATE.jcl) | VSAM Transaction Update | **CC 0004** | `TRANS.AUDIT`, `TRANS.REJECT` |
| **11** | `HRBSJ06` | [JOB06_COBOL_BILL.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB06_COBOL_BILL.jcl) | COBOL Billing Engine | **CC 0000** | `INVOICE.OUTPUT` (90 invoices) |
| **12** | `HRBSJ11` | [JOB11_REPORT.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB11_REPORT.jcl) | 132-Col Billing Report | **CC 0000** | `BILLING.REPORT` (Formatted print) |
| **13** | `HRBSJ05` | [JOB05_DB2_SCHEMA.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB05_DB2_SCHEMA.jcl) | DB2 DDL Schema Deploy | **CC 0000** | DSNTEP2 creates 5 tables & indexes |
| **14** | `HRBSJ12` | [JOB12_DB2_LOAD_REPORT.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB12_DB2_LOAD_REPORT.jcl) | DB2 Load & Cursor Query | **CC 0000** | Inserts rows, queries unpaid bills |
| **15** | `HRBSBCH` | [JOB10_HRBS_BATCH_CYCLE.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB10_HRBS_BATCH_CYCLE.jcl) | Master Batch Cycle | **CC 0000** | Executes entire end-to-end flow |

---

## 2. Step-by-Step Verification in ISPF / SDSF

### Verifying Job Completion in SDSF
1. From ISPF Primary Option Menu, type `=S.ST` (SDSF Status Panel).
2. Enter command: `PREFIX *` or `PREFIX <userid>*` to filter your jobs.
3. Locate the submitted job (e.g. `HRBSJ01`).
4. Check the `RetCode` column:
   - Must show `CC 0000` (or `CC 0008` for the intentional FAIL test `HRBSJ04F`).
5. Type `?` next to the job name to view spool datasets:
   - Select `JESMSGLG` with `S` to review job start/end timestamps and step return codes.
   - Select `SYSOUT` / `SYSPRINT` with `S` to review program summary counts and error messages.

### Verifying Datasets in ISPF 3.4
1. From ISPF Primary Option Menu, type `=3.4` (Data Set List Utility).
2. Enter Dsname Level: `<userid>.HRBS.*` and press Enter.
3. Type `V` (View) or `B` (Browse) next to any dataset:
   - Open `<userid>.HRBS.RESERV.SORTED`: Type `COLS` on the command line to show the column ruler. Verify keys at columns 13–20 are strictly ascending.
   - Open `<userid>.HRBS.BILLING.REPORT`: Verify 132-column alignment, page headers, subtotals, and grand totals.

---

## 3. Mandatory Viva & Presentation Screenshot Checklist

Capture the following screens on z/OS to include in your presentation slides:

- [ ] **Screenshot 1: ISPF 3.4 Dataset List (`<userid>.HRBS.*`)** showing all sequential and partitioned datasets with proper tracks and attributes.
- [ ] **Screenshot 2: Input Dataset in ISPF Edit Mode with `COLS` Ruler** showing primary key columns 13–20 for `RESERV.INPUT`.
- [ ] **Screenshot 3: JOB01 SDSF Log (`JESMSGLG`) and CC 0000** showing DFSORT input (100) and output (90).
- [ ] **Screenshot 4: JOB02 HRBSMTCH SYSOUT Report** showing 50 read, 50 loaded, 35 matched, and 15 without payment.
- [ ] **Screenshot 5: JOB03 HRBSDEDP SYSTSPRT Output** showing REXX records read (120), duplicates dropped (15), and records written (105).
- [ ] **Screenshot 6: JOB04 PASS vs FAIL Comparison**:
  - `JOB04P`: `CC 0000` with message `**** RECORD COUNT BEFORE = AFTER SORT. OUTPUT FILE KEPT. ****`.
  - `JOB04F`: `CC 0008` with message `**** ERROR: RECORD COUNT MISMATCH AFTER SORT. OUTPUT NOT KEPT. ****`.
- [ ] **Screenshot 7: JOB07 HRBSVAL Summary** displaying valid records (90) and reject records (15).
- [ ] **Screenshot 8: JOB08 IDCAMS KSDS REPRO Log** confirming successful VSAM cluster definition and initial load.
- [ ] **Screenshot 9: JOB09 HRBSUPD VSAM Transaction Audit Log** displaying processed additions, cancellations, check-outs, and deliberate rejects.
- [ ] **Screenshot 10: JOB06 HRBSBIL Billing Summary** displaying total reservations read (90) and grand total billed.
- [ ] **Screenshot 11: JOB11 Formatted 132-Column Billing Report** showing room-type control breaks and subtotals.
- [ ] **Screenshot 12: JOB05 / JOB12 DB2 Query Output** showing tabular results for Revenue by Room Type and Unpaid Bills.
