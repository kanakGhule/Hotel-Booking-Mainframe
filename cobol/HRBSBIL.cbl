       IDENTIFICATION DIVISION.
       PROGRAM-ID. HRBSBIL.
      *****************************************************************
      * HOTEL RESERVATION AND BILLING SYSTEM (HRBS)
      * BILLING MODULE - GENERATES ONE INVOICE PER CONFIRMED /
      *                  CHECKED-OUT BOOKING
      *
      * INPUT  (RESVIN)  : RESERVATIONS, 80 BYTES (VALIDATED/SORTED)
      * OPTIONAL (SRVFILE): EXTRA CHARGES, 80 BYTES (SERVICE FILE)
      * OUTPUT (INVOUT)  : INVOICES,    100 BYTES, KEY = COLS 25-32
      *
      * BUSINESS RULES:
      * 1. BILL ONLY STATUS 'C' (CONFIRMED) OR 'O' (CHECKED-OUT).
      * 2. NIGHTS = CHECK-OUT - CHECK-IN (MINIMUM 1 NIGHT).
      * 3. ROOM CHARGE = NIGHTS * RATE.
      * 4. SERVICE CHARGE = 5% BASE ROOM CHARGE + EXTRA CHARGES.
      * 5. GST SLABS: 5% IF RATE <= 7500, 18% IF RATE > 7500.
      * 6. TAX = (ROOM CHARGE + SERVICE CHARGE) * TAX RATE.
      * 7. TOTAL = ROOM CHARGE + SERVICE CHARGE + TAX.
      *
      * RETURN CODES:
      *   00 = NORMAL COMPLETION
      *   16 = FILE OPEN OR SEVERE I/O ERROR
      *****************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT RESV-FILE ASSIGN TO RESVIN
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS1.
           SELECT OPTIONAL SRV-FILE ASSIGN TO SRVFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-SRV.
           SELECT INV-FILE  ASSIGN TO INVOUT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS2.

       DATA DIVISION.
       FILE SECTION.
       FD  RESV-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  RESV-REC.
           05 RV-TYPE             PIC X(03).
           05 RV-HOTEL            PIC X(03).
           05 RV-BKDATE           PIC X(06).
           05 RV-ID               PIC X(08).
           05 RV-NAME             PIC X(20).
           05 RV-ROOM             PIC X(04).
           05 RV-RTYPE            PIC X(04).
           05 RV-CHKIN            PIC 9(08).
           05 RV-CHKOUT           PIC 9(08).
           05 RV-GUESTS           PIC 9(02).
           05 RV-RATE             PIC 9(06).
           05 RV-STATUS           PIC X(01).
           05 FILLER              PIC X(07).

       FD  SRV-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  SRV-REC.
           05 SRV-RES-ID          PIC X(08).
           05 FILLER              PIC X(01).
           05 SRV-CODE            PIC X(04).
           05 FILLER              PIC X(01).
           05 SRV-AMOUNT          PIC 9(06)V99.
           05 FILLER              PIC X(58).

       FD  INV-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  INV-REC.
           05 INV-TYPE            PIC X(03).
           05 INV-HOTEL           PIC X(03).
           05 INV-DATE            PIC X(08).
           05 INV-GUEST           PIC X(10).
           05 INV-ID              PIC X(08).
           05 INV-RES             PIC X(08).
           05 INV-NAME            PIC X(20).
           05 INV-NIGHTS          PIC 9(03).
           05 INV-ROOM            PIC 9(06)V99.
           05 INV-SVC             PIC 9(06)V99.
           05 INV-TAX             PIC 9(06)V99.
           05 INV-TOT             PIC 9(08)V99.
           05 INV-STATUS          PIC X(01).
           05 FILLER              PIC X(02).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05 WS-FS1              PIC XX VALUE '00'.
           05 WS-FS2              PIC XX VALUE '00'.
           05 WS-FS-SRV           PIC XX VALUE '00'.

       01  WS-FLAGS.
           05 WS-EOF-RESV         PIC X VALUE 'N'.
              88 END-OF-RESV      VALUE 'Y'.
           05 WS-EOF-SRV          PIC X VALUE 'N'.
              88 END-OF-SRV       VALUE 'Y'.
           05 WS-SRV-ACTIVE       PIC X VALUE 'N'.
              88 SRV-FILE-PRESENT VALUE 'Y'.

      *---- BILLING POLICY PARAMETERS --------------------------------*
       01  WS-BILLING-PARAMETERS.
           05 PARM-BASE-SVC-RATE  PIC 9V99 VALUE 0.05.
           05 PARM-GST-SLAB-LIMIT PIC 9(06) VALUE 7500.
           05 PARM-GST-LOW-RATE   PIC 9V99 VALUE 0.05.
           05 PARM-GST-HIGH-RATE  PIC 9V99 VALUE 0.18.

      *---- COUNTERS AND ACCUMULATORS --------------------------------*
       01  WS-COUNTERS.
           05 WS-READ-CNT         PIC 9(05) VALUE 0.
           05 WS-BILL-CNT         PIC 9(05) VALUE 0.
           05 WS-SKIP-CNT         PIC 9(05) VALUE 0.
           05 WS-SRV-CNT          PIC 9(05) VALUE 0.
           05 WS-SEQ              PIC 9(06) VALUE 0.
           05 WS-GUEST-SEQ        PIC 9(09) VALUE 0.

      *---- INTERMEDIATE CALCULATION FIELDS --------------------------*
       01  WS-CALCS.
           05 WS-NIGHTS           PIC S9(05) COMP-3.
           05 WS-ROOM             PIC 9(06)V99.
           05 WS-BASE-SVC         PIC 9(06)V99.
           05 WS-EXTRA-SVC        PIC 9(06)V99.
           05 WS-SVC              PIC 9(06)V99.
           05 WS-TAX              PIC 9(06)V99.
           05 WS-TAX-RATE         PIC 9V99.
           05 WS-TOT              PIC 9(08)V99.
           05 WS-GRAND-TOTAL      PIC 9(10)V99 VALUE 0.
           05 WS-GRAND-EDIT       PIC Z,ZZZ,ZZZ,ZZ9.99.
           05 WS-TODAY            PIC X(08).

      *---- IN-MEMORY SERVICE TABLE (UP TO 200 EXTRA CHARGES) --------*
       01  WS-SERVICE-TABLE.
           05 ST-COUNT            PIC 9(04) VALUE 0.
           05 ST-ENTRY OCCURS 200 TIMES INDEXED BY ST-IDX.
              10 ST-RES-ID        PIC X(08).
              10 ST-CODE          PIC X(04).
              10 ST-AMOUNT        PIC 9(06)V99.

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-OPEN-FILES
           IF SRV-FILE-PRESENT
              PERFORM 1500-LOAD-SERVICES
           END-IF
           PERFORM 2000-PROCESS UNTIL END-OF-RESV
           PERFORM 3000-CLOSE-AND-REPORT
           STOP RUN.

       1000-OPEN-FILES.
           MOVE FUNCTION CURRENT-DATE (1:8) TO WS-TODAY
           OPEN INPUT RESV-FILE
           IF WS-FS1 NOT = '00'
              DISPLAY 'HRBSBIL: RESV-FILE OPEN ERROR FS=' WS-FS1
              MOVE 16 TO RETURN-CODE
              STOP RUN
           END-IF

           OPEN INPUT SRV-FILE
           IF WS-FS-SRV = '00'
              SET SRV-FILE-PRESENT TO TRUE
           ELSE
              IF WS-FS-SRV = '05'
                 DISPLAY 'HRBSBIL: OPTIONAL SERVICE FILE NOT PRESENT'
              ELSE
                 DISPLAY 'HRBSBIL: SERVICE FILE OPEN ERROR FS='
                         WS-FS-SRV
                 MOVE 16 TO RETURN-CODE
                 STOP RUN
              END-IF
           END-IF

           OPEN OUTPUT INV-FILE
           IF WS-FS2 NOT = '00'
              DISPLAY 'HRBSBIL: INV-FILE OPEN ERROR FS=' WS-FS2
              MOVE 16 TO RETURN-CODE
              STOP RUN
           END-IF

           PERFORM 1100-READ-RESV.

       1100-READ-RESV.
           READ RESV-FILE
              AT END SET END-OF-RESV TO TRUE
              NOT AT END ADD 1 TO WS-READ-CNT
           END-READ.

       1500-LOAD-SERVICES.
           READ SRV-FILE
              AT END SET END-OF-SRV TO TRUE
           END-READ
           PERFORM UNTIL END-OF-SRV OR ST-COUNT >= 200
              ADD 1 TO ST-COUNT
              MOVE SRV-RES-ID TO ST-RES-ID (ST-COUNT)
              MOVE SRV-CODE   TO ST-CODE   (ST-COUNT)
              MOVE SRV-AMOUNT TO ST-AMOUNT (ST-COUNT)
              ADD 1 TO WS-SRV-CNT
              READ SRV-FILE
                 AT END SET END-OF-SRV TO TRUE
              END-READ
           END-PERFORM
           DISPLAY 'HRBSBIL: EXTRA SERVICES LOADED = ' WS-SRV-CNT.

       2000-PROCESS.
           IF RV-STATUS = 'C' OR RV-STATUS = 'O'
              PERFORM 2100-BUILD-INVOICE
           ELSE
              ADD 1 TO WS-SKIP-CNT
           END-IF
           PERFORM 1100-READ-RESV.

       2100-BUILD-INVOICE.
      *---- CALCULATE NIGHTS (MINIMUM 1) -----------------------------*
           COMPUTE WS-NIGHTS =
               FUNCTION INTEGER-OF-DATE (RV-CHKOUT)
             - FUNCTION INTEGER-OF-DATE (RV-CHKIN)
           IF WS-NIGHTS < 1
              MOVE 1 TO WS-NIGHTS
           END-IF

      *---- BASE ROOM CHARGES ----------------------------------------*
           COMPUTE WS-ROOM = WS-NIGHTS * RV-RATE
           COMPUTE WS-BASE-SVC ROUNDED =
               WS-ROOM * PARM-BASE-SVC-RATE

      *---- EXTRA SERVICE CHARGES FROM TABLE -------------------------*
           MOVE 0 TO WS-EXTRA-SVC
           IF SRV-FILE-PRESENT AND ST-COUNT > 0
              PERFORM VARYING ST-IDX FROM 1 BY 1
                      UNTIL ST-IDX > ST-COUNT
                 IF ST-RES-ID (ST-IDX) = RV-ID
                    ADD ST-AMOUNT (ST-IDX) TO WS-EXTRA-SVC
                 END-IF
              END-PERFORM
           END-IF

           COMPUTE WS-SVC = WS-BASE-SVC + WS-EXTRA-SVC

      *---- TIERED GST CALCULATION -----------------------------------*
           IF RV-RATE > PARM-GST-SLAB-LIMIT
              MOVE PARM-GST-HIGH-RATE TO WS-TAX-RATE
           ELSE
              MOVE PARM-GST-LOW-RATE  TO WS-TAX-RATE
           END-IF

           COMPUTE WS-TAX ROUNDED =
               (WS-ROOM + WS-SVC) * WS-TAX-RATE
           COMPUTE WS-TOT = WS-ROOM + WS-SVC + WS-TAX

      *---- FORMAT 100-BYTE INVOICE RECORD ---------------------------*
           ADD 1 TO WS-SEQ
           ADD 1 TO WS-GUEST-SEQ
           MOVE SPACES             TO INV-REC
           MOVE 'INV'              TO INV-TYPE
           MOVE RV-HOTEL           TO INV-HOTEL
           MOVE WS-TODAY           TO INV-DATE
           STRING 'G' WS-GUEST-SEQ DELIMITED BY SIZE INTO INV-GUEST
           STRING 'IN' WS-SEQ      DELIMITED BY SIZE INTO INV-ID
           MOVE RV-ID              TO INV-RES
           MOVE RV-NAME            TO INV-NAME
           MOVE WS-NIGHTS          TO INV-NIGHTS
           MOVE WS-ROOM            TO INV-ROOM
           MOVE WS-SVC             TO INV-SVC
           MOVE WS-TAX             TO INV-TAX
           MOVE WS-TOT             TO INV-TOT
           MOVE 'P'                TO INV-STATUS
           MOVE SPACES             TO FILLER OF INV-REC

           WRITE INV-REC
           ADD 1 TO WS-BILL-CNT
           ADD WS-TOT TO WS-GRAND-TOTAL.

       3000-CLOSE-AND-REPORT.
           CLOSE RESV-FILE INV-FILE
           IF SRV-FILE-PRESENT
              CLOSE SRV-FILE
           END-IF
           MOVE WS-GRAND-TOTAL TO WS-GRAND-EDIT
           DISPLAY '-------------------------------------------'
           DISPLAY 'HRBSBIL - BILLING RUN SUMMARY'
           DISPLAY 'RESERVATIONS READ : ' WS-READ-CNT
           DISPLAY 'INVOICES WRITTEN  : ' WS-BILL-CNT
           DISPLAY 'SKIPPED (NOT CONF): ' WS-SKIP-CNT
           DISPLAY 'EXTRA SRV LOADED  : ' WS-SRV-CNT
           DISPLAY 'TOTAL BILLED      : ' WS-GRAND-EDIT
           DISPLAY '-------------------------------------------'.
