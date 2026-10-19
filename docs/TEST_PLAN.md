# HRBS - Master Test Plan & Verification Matrix

**Hotel Reservation and Billing System (HRBS)**  
Course: Mainframe Technology (ID3002) | AY 2026-27 Sem-1 | VIT Pune  

---

## 1. Overview & Testing Strategy

This test plan defines the test cases, test inputs, execution steps, expected outcomes, and target return codes across the HRBS suite. Testing incorporates both:
1. **Positive Functional Testing:** Verifying standard production paths (deduplication, matching, VSAM updates, GST calculation, reporting, DB2 loads).
2. **Negative & Edge-Case Testing:** Deliberately testing data corruption, key violations, room double-booking, invalid calendar dates, and count mismatches.

---

## 2. Test Case Specification Matrix

| Test ID | Component | Input Dataset | Test Scenario Description | Expected Output | Expected RC |
|---|---|---|---|---|---|
| **TC-01** | `JOB01` (DFSORT) | `RESERV.dat` | Deduplication on cols 13-20 & ascending sort | 100 recs $\rightarrow$ 90 unique sorted recs; matches `EXPECTED_A1.dat` | **CC 0000** |
| **TC-02** | `JOB02` (HRBSMTCH) | `FILE1.dat`, `FILE2.dat` | Match reservations (50) with payments (50) | 35 matched pairs written to `FILE3` (160 B); 15 without payment | **CC 0000** |
| **TC-03** | `JOB03` (HRBSDEDP) | `INVOICE.dat` | REXX stem deduplication & shell sort on cols 25-32 | 120 recs $\rightarrow$ 105 unique sorted recs; matches `EXPECTED_A3.dat` | **CC 0000** |
| **TC-04A** | `JOB04P` (ICETOOL) | `RESERV.dat` | Record count audit before = after sort (PASS) | `&&CMP` has 1 count rec; `A4.OUTPUT` kept | **CC 0000** |
| **TC-04B** | `JOB04F` (ICETOOL) | `RESERV.dat` | Count mismatch simulation via `STOPAFT=90` (FAIL) | `&&CMP` has 2 count recs; error printed; output discarded | **CC 0008** |
| **TC-05** | `JOB07` (HRBSVAL) | `RESERV_BAD.dat` (Rec 1) | Record type not `'RSV'` (`'BAD'`) | Diverted to `REJOUT` with reason code `'01'` | **CC 0004** |
| **TC-06** | `JOB07` (HRBSVAL) | `RESERV_BAD.dat` (Rec 2-3)| Invalid res ID prefix (`'XX'`) / non-numeric | Diverted to `REJOUT` with reason code `'02'` | **CC 0004** |
| **TC-07** | `JOB07` (HRBSVAL) | `RESERV_BAD.dat` (Rec 4) | Invalid booking date month (`261301`) | Diverted to `REJOUT` with reason code `'03'` | **CC 0004** |
| **TC-08** | `JOB07` (HRBSVAL) | `RESERV_BAD.dat` (Rec 5-6)| Invalid check-in month (`13`) / Feb 30th | Diverted to `REJOUT` with reason code `'04'` | **CC 0004** |
| **TC-09** | `JOB07` (HRBSVAL) | `RESERV_BAD.dat` (Rec 7) | Invalid check-out day (Nov 31st) | Diverted to `REJOUT` with reason code `'05'` | **CC 0004** |
| **TC-10** | `JOB07` (HRBSVAL) | `RESERV_BAD.dat` (Rec 8-9)| Check-out date before or same as check-in | Diverted to `REJOUT` with reason code `'06'` | **CC 0004** |
| **TC-11** | `JOB07` (HRBSVAL) | `RESERV_BAD.dat` (Rec 10)| Invalid room type (`'PRE '`) | Diverted to `REJOUT` with reason code `'07'` | **CC 0004** |
| **TC-12** | `JOB07` (HRBSVAL) | `RESERV_BAD.dat` (Rec 11-12)| Guest count out of range (`0` or `5`) | Diverted to `REJOUT` with reason code `'08'` | **CC 0004** |
| **TC-13** | `JOB07` (HRBSVAL) | `RESERV_BAD.dat` (Rec 13-14)| Tariff inconsistent with room type table | Diverted to `REJOUT` with reason code `'09'` | **CC 0004** |
| **TC-14** | `JOB07` (HRBSVAL) | `RESERV_BAD.dat` (Rec 15)| Invalid reservation status (`'Z'`) | Diverted to `REJOUT` with reason code `'10'` | **CC 0004** |
| **TC-15** | `JOB08` (IDCAMS) | `RESERV.VALID` | Define KSDS cluster and initial REPRO | KSDS defined with key (8,12); 90 records loaded | **CC 0000** |
| **TC-16** | `JOB09` (HRBSUPD) | `TRANS.dat` (Rec 1-6) | Valid reservation additions (`Action 'A'`) | Written to KSDS; audit entry written with `'OK'` | **CC 0000** |
| **TC-17** | `JOB09` (HRBSUPD) | `TRANS.dat` (Rec 7-8) | Duplicate key addition (`RS006881`) | Rejected with code `'22'`; written to `REJOUT` | **CC 0004** |
| **TC-18** | `JOB09` (HRBSUPD) | `TRANS.dat` (Rec 9-10)| Room availability double-booking overlap | Rejected with code `'RO'`; written to `REJOUT` | **CC 0004** |
| **TC-19** | `JOB09` (HRBSUPD) | `TRANS.dat` (Rec 11-15)| Valid cancellation (`Action 'C'`) | KSDS status updated to `'X'`; audit `'OK'` | **CC 0000** |
| **TC-20** | `JOB09` (HRBSUPD) | `TRANS.dat` (Rec 16-17)| Cancellation on non-existent ID (`RS009991`) | Rejected with code `'23'`; written to `REJOUT` | **CC 0004** |
| **TC-21** | `JOB09` (HRBSUPD) | `TRANS.dat` (Rec 18-23)| Valid guest check-out (`Action 'O'`) | KSDS status updated to `'O'`; audit `'OK'` | **CC 0000** |
| **TC-22** | `JOB09` (HRBSUPD) | `TRANS.dat` (Rec 24-25)| Check-out on non-existent ID (`RS009993`) | Rejected with code `'23'`; written to `REJOUT` | **CC 0004** |
| **TC-23** | `JOB09` (HRBSUPD) | `TRANS.dat` (Rec 26-28)| Valid rate / date update (`Action 'U'`) | KSDS record rewritten with new values; audit `'OK'`| **CC 0000** |
| **TC-24** | `JOB09` (HRBSUPD) | `TRANS.dat` (Rec 29-31)| Invalid transaction action code (`'Z'`, `'X'`)| Rejected with code `'99'`; written to `REJOUT` | **CC 0004** |
| **TC-25** | `JOB06` (HRBSBIL) | `RESERV.VALID` | Billing confirmed ('C') and checked-out ('O') | Invoices formatted; 5% svc + tiered GST applied | **CC 0000** |
| **TC-26** | `JOB06` (HRBSBIL) | `SERVICE.dat` | Aggregate extra services into invoice total | Extra service amounts added to service charge | **CC 0000** |
| **TC-27** | `JOB11` (HRBSRPT) | `INVOICE.OUTPUT` | 132-col report with control breaks | Subtotals per room type (STD, DLX, STE) + Grand Tot| **CC 0000** |
| **TC-28** | `JOB12` (HRBSDB2) | `RESERV.VALID` | DB2 batch load with SQLCODE -803 handling | Rows inserted into `RESERVATION` and `BILL` | **CC 0000** |
| **TC-29** | `JOB12` (HRBSDB2) | DB2 Tables | Cursor `C_UNPAID` query for unpaid invoices | Joined query outputs unpaid invoices in spool | **CC 0000** |
| **TC-30** | Edge Case | `EMPTY.dat` | Empty dataset processed by REXX / COBOL | 0 records read; clean EOF handled without abend | **CC 0000** |
| **TC-31** | Edge Case | `SINGLE_REC.dat` | 1-record dataset processed | 1 record read and written; clean completion | **CC 0000** |
| **TC-32** | Edge Case | `MAX_LEN_NAMES.dat` | Maximum 20-character guest names | Names properly aligned without truncation | **CC 0000** |
| **TC-33** | Edge Case | `PAY_MISMATCH.dat` | Payment amount not equal to invoice total | Unpaid query detects outstanding balances | **CC 0000** |
