# HRBS - Project Context (use this to build the presentation)

## Project
Title: **Hotel Reservation and Billing System (HRBS)**. Batch mainframe application: validates and orders hotel reservation records, matches reservations with payments, generates invoices with tax, cleans invoice data, and reports from DB2.
Institute: BRACT's Vishwakarma Institute of Technology, Pune-37, Dept. of Computer Engineering. Subject: Mainframe Technology (ID3002)(PEC-I). Mentor: Mrs Madhura Sanap (VIT, Pune). AY 2026-27 (Sem-1).
Student details (names, PRN, roll no., branch, class, div): NOT provided - leave as placeholders for the student to fill.

## Business problem
Manual reservation/billing: duplicate bookings, mismatched payments, calculation errors, slow month-end billing. Mainframes suit this because of high-volume batch, data integrity, reliability, and mature JCL/COBOL/DB2 tooling.

## Objectives
Remove duplicate reservations; keep records ordered by key; match reservations to payments; compute room + service + tax correctly; verify record counts around every transformation; keep a relational DB2 copy for queries.

## Architecture (end to end)
Input PS datasets (Reservations, Payments, Invoices)
-> JCL SORT (dedupe/sort) -> COBOL (HRBSMTCH match, HRBSBIL billing) -> REXX (HRBSDEDP clean-up of invoice data) -> JCL copy with count validation (ICETOOL) -> DB2 tables (GUEST, ROOM, RESERVATION, BILL, PAYMENT) -> output datasets/reports.
Controls: DISP=(NEW,CATLG,DELETE), return-code checks (COND / IF-ELSE), count reconciliation, error message and RC 8 on failure.

## Record layouts (fixed block, EBCDIC on z/OS)
RESERVATION, 80 B: 1-3 type 'RSV'; 4-6 hotel; 7-12 booking date YYMMDD; **13-20 RESERVATION-ID (key)**; 21-40 guest name; 41-44 room no; 45-48 room type; 49-56 check-in; 57-64 check-out; 65-66 guests; 67-72 rate/night; 73 status; 74-80 filler.
PAYMENT, 80 B: 1-3 'PAY'; 4-11 payment id; 12-17 date; 18-20 mode (CSH/CRD/UPI); **21-28 RESERVATION-ID (key)**; 29-38 amount 9(8)V99; 39-58 payer; 59-80 filler.
INVOICE, 100 B: 1-3 'INV'; 4-6 hotel; 7-14 bill date; 15-24 guest id; **25-32 INVOICE-ID (key)**; 33-40 reservation id; 41-60 guest name; 61-63 nights; 64-71 room charge; 72-79 service charge; 80-87 tax; 88-97 total; 98 status; 99-100 filler. Money fields are zoned 9(n)V99 with implied decimal.

## Implementation per assignment
1. JOB01: DFSORT `SORT FIELDS=(13,8,CH,A)` + `SUM FIELDS=NONE`; 100 in -> 90 out.
2. HRBSMTCH (COBOL): loads FILE2 into a 100-entry table, reads FILE1, writes matches to FILE3 (160 B); 50 + 50 in -> 35 matched, 15 reservations without payment.
3. HRBSDEDP (REXX): EXECIO read into stem, dedupe with stem-based seen table, shell sort on cols 25-32, EXECIO write; 120 in -> 105 out.
4. JOB04: count before (OUTFIL TRAILER1 COUNT), SORT descending to temp dataset, count after, merge+SUM FIELDS=NONE then ICETOOL COUNT to set RC, IF/ELSE to keep output (copy to catalogued dataset) or print error + RC 8. Failure is simulated with `OPTION STOPAFT=90`.
5. Billing (HRBSBIL): nights via INTEGER-OF-DATE, room = nights x rate, service = 5%, tax by rate slab, total.
6. DB2: 5 tables with PK/FK, unique indexes, 3 reporting queries, DSNTEP2 batch job.

## Slide plan for the teacher's template (11 slides; keep template layout, headings, footer, logo)
1 Title: project title, student table (placeholders), mentor, AY.
2 Project Overview: purpose/scope, business problem, objectives/outcomes, stakeholders (front desk, accounts, manager), scope + assumptions.
3 Abstract: problem, mainframe solution, technologies JCL/COBOL/REXX/DB2, key results (100->90, 35 matches, 120->105, count check pass/fail).
4 Introduction: hotel domain, why mainframe, existing pain points, solution at a glance.
5 Problem Statement & Objectives: functional + non-functional requirements, error reduction, reliability.
6 Mainframe Architecture: diagram of the flow above; security/logging/controls.
7 Mainframe Methodology: requirements, dataset + job design, development + unit test, integration test + batch run, error handling/restart/validation.
8 Dataset & File Operations (part 1): dataset allocation (ISPF 3.2, ALLOCATE.jcl, DCB/SPACE/DISP), record layouts.
9 Dataset & File Operations (part 2): the 4 assignments - JCL/COBOL/REXX snippets and what each does.
10 Points to be Covered: Results & Performance (tables of expected vs actual, screenshots), Challenges & Solutions, Conclusion, Future Enhancements (online CICS reservation screens, VSAM KSDS master, DB2 embedded SQL, GST rules table, scheduling with TWS), References.
11 Thank You.
