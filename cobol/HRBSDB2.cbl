       IDENTIFICATION DIVISION.
       PROGRAM-ID. HRBSDB2.
      *****************************************************************
      * HOTEL RESERVATION AND BILLING SYSTEM (HRBS)
      * DB2 BATCH LOADER AND REPORTING MODULE (EMBEDDED SQL)
      *
      * INPUT  (RESVIN) : VALIDATED RESERVATION FILE (LRECL 80)
      * INPUT  (INVIN)  : GENERATED INVOICE FILE (LRECL 100)
      *
      * FUNCTIONALITY:
      * 1. INSERTS RESERVATIONS INTO HRBS.RESERVATION TABLE.
      * 2. INSERTS INVOICES INTO HRBS.BILL TABLE.
      * 3. HANDLES DUPLICATE KEYS (SQLCODE -803) GRACEFULLY.
      * 4. ISSUES PERIODIC COMMIT (EVERY 25 ROWS) AND FINAL COMMIT.
      * 5. RUNS A CURSOR-BASED REPORT TO DISPLAY UNPAID BILLS.
      *
      * RETURN CODES:
      *   00 = NORMAL COMPLETION
      *   12 = FATAL DB2 SQL ERROR (ROLLBACK ISSUED)
      *****************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT RESV-FILE ASSIGN TO RESVIN
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-RESV.
           SELECT INV-FILE  ASSIGN TO INVIN
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-INV.

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

       FD  INV-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  INV-REC.
           05 IV-TYPE             PIC X(03).
           05 IV-HOTEL            PIC X(03).
           05 IV-DATE             PIC X(08).
           05 IV-GUEST            PIC X(10).
           05 IV-ID               PIC X(08).
           05 IV-RES              PIC X(08).
           05 IV-NAME             PIC X(20).
           05 IV-NIGHTS           PIC 9(03).
           05 IV-ROOM             PIC 9(06)V99.
           05 IV-SVC              PIC 9(06)V99.
           05 IV-TAX              PIC 9(06)V99.
           05 IV-TOT              PIC 9(08)V99.
           05 IV-STATUS           PIC X(01).
           05 FILLER              PIC X(02).

       WORKING-STORAGE SECTION.
      *---- DB2 SQL COMMUNICATION AREA -------------------------------*
           EXEC SQL INCLUDE SQLCA END-EXEC.

      *---- HOST VARIABLES / DCLGEN INCLUDES -------------------------*
       01  DCL-RESERVATION.
           10 HV-RES-ID           PIC X(08).
           10 HV-RESV-GUEST-ID    PIC X(10).
           10 HV-RESV-ROOM-NO     PIC X(04).
           10 HV-CHECK-IN         PIC X(10).
           10 HV-CHECK-OUT        PIC X(10).
           10 HV-NO-OF-GUESTS     PIC S9(4) USAGE COMP.
           10 HV-RESV-STATUS      PIC X(01).

       01  DCL-BILL.
           10 HV-INVOICE-ID       PIC X(08).
           10 HV-BILL-RES-ID      PIC X(08).
           10 HV-BILL-DATE        PIC X(10).
           10 HV-NIGHTS           PIC S9(4) USAGE COMP.
           10 HV-ROOM-CHARGE      PIC S9(8)V99 USAGE COMP-3.
           10 HV-SERVICE-CHARGE   PIC S9(8)V99 USAGE COMP-3.
           10 HV-TAX              PIC S9(8)V99 USAGE COMP-3.
           10 HV-TOTAL            PIC S9(10)V99 USAGE COMP-3.
           10 HV-PAY-STATUS       PIC X(01).

       01  HV-REPORT-VARS.
           10 HV-REP-INVID        PIC X(08).
           10 HV-REP-GNAME        PIC X(30).
           10 HV-REP-TOTAL        PIC S9(10)V99 USAGE COMP-3.

       01  WS-FILE-STATUS.
           05 WS-FS-RESV          PIC XX VALUE '00'.
           05 WS-FS-INV           PIC XX VALUE '00'.

       01  WS-FLAGS.
           05 WS-EOF-RESV         PIC X VALUE 'N'.
              88 END-OF-RESV      VALUE 'Y'.
           05 WS-EOF-INV          PIC X VALUE 'N'.
              88 END-OF-INV       VALUE 'Y'.
           05 WS-EOF-CURSOR       PIC X VALUE 'N'.
              88 END-OF-CURSOR    VALUE 'Y'.

       01  WS-COUNTERS.
           05 WS-RESV-INS-CNT     PIC 9(05) VALUE 0.
           05 WS-RESV-DUP-CNT     PIC 9(05) VALUE 0.
           05 WS-BILL-INS-CNT     PIC 9(05) VALUE 0.
           05 WS-BILL-DUP-CNT     PIC 9(05) VALUE 0.
           05 WS-COMMIT-FREQ      PIC 9(03) VALUE 25.
           05 WS-PENDING-OPS      PIC 9(03) VALUE 0.
           05 WS-UNPAID-CNT       PIC 9(05) VALUE 0.

       01  WS-DISPLAY-TOTAL       PIC Z,ZZZ,ZZ9.99.

      *---- CURSOR FOR UNPAID BILLS ----------------------------------*
           EXEC SQL
             DECLARE C_UNPAID CURSOR FOR
             SELECT B.INVOICE_ID, G.GUEST_NAME, B.TOTAL
               FROM HRBS.BILL B, HRBS.RESERVATION V, HRBS.GUEST G
              WHERE B.RES_ID = V.RES_ID
                AND V.GUEST_ID = G.GUEST_ID
                AND B.TOTAL > (SELECT COALESCE(SUM(P.AMOUNT), 0)
                                 FROM HRBS.PAYMENT P
                                WHERE P.RES_ID = B.RES_ID)
           END-EXEC.

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-OPEN-FILES
           PERFORM 2000-LOAD-RESERVATIONS
           PERFORM 3000-LOAD-INVOICES
           EXEC SQL COMMIT WORK END-EXEC
           PERFORM 4000-REPORT-UNPAID-BILLS
           PERFORM 5000-CLOSE-FILES
           STOP RUN.

       1000-OPEN-FILES.
           OPEN INPUT RESV-FILE
           IF WS-FS-RESV NOT = '00'
              DISPLAY 'HRBSDB2: RESV-FILE OPEN ERROR FS=' WS-FS-RESV
              MOVE 12 TO RETURN-CODE
              STOP RUN
           END-IF

           OPEN INPUT INV-FILE
           IF WS-FS-INV NOT = '00'
              DISPLAY 'HRBSDB2: INV-FILE OPEN ERROR FS=' WS-FS-INV
              MOVE 12 TO RETURN-CODE
              STOP RUN
           END-IF.

       2000-LOAD-RESERVATIONS.
           READ RESV-FILE
              AT END SET END-OF-RESV TO TRUE
           END-READ
           PERFORM UNTIL END-OF-RESV
              PERFORM 2100-INSERT-RESERVATION
              READ RESV-FILE
                 AT END SET END-OF-RESV TO TRUE
              END-READ
           END-PERFORM.

       2100-INSERT-RESERVATION.
           MOVE RV-ID             TO HV-RES-ID
           STRING 'G000000001' DELIMITED BY SIZE INTO HV-RESV-GUEST-ID
           MOVE RV-ROOM           TO HV-RESV-ROOM-NO
           STRING RV-CHKIN (1:4) '-' RV-CHKIN (5:2) '-'
                  RV-CHKIN (7:2) DELIMITED BY SIZE INTO HV-CHECK-IN
           STRING RV-CHKOUT (1:4) '-' RV-CHKOUT (5:2) '-'
                  RV-CHKOUT (7:2) DELIMITED BY SIZE INTO HV-CHECK-OUT
           MOVE RV-GUESTS         TO HV-NO-OF-GUESTS
           MOVE RV-STATUS         TO HV-RESV-STATUS

           EXEC SQL
             INSERT INTO HRBS.RESERVATION
               (RES_ID, GUEST_ID, ROOM_NO, CHECK_IN, CHECK_OUT,
                NO_OF_GUESTS, STATUS)
             VALUES
               (:HV-RES-ID, :HV-RESV-GUEST-ID, :HV-RESV-ROOM-NO,
                DATE(:HV-CHECK-IN), DATE(:HV-CHECK-OUT),
                :HV-NO-OF-GUESTS, :HV-RESV-STATUS)
           END-EXEC

           IF SQLCODE = 0
              ADD 1 TO WS-RESV-INS-CNT
              ADD 1 TO WS-PENDING-OPS
           ELSE
              IF SQLCODE = -803
                 ADD 1 TO WS-RESV-DUP-CNT
              ELSE
                 PERFORM 9999-SQL-ERROR
              END-IF
           END-IF

           IF WS-PENDING-OPS >= WS-COMMIT-FREQ
              EXEC SQL COMMIT WORK END-EXEC
              MOVE 0 TO WS-PENDING-OPS
           END-IF.

       3000-LOAD-INVOICES.
           READ INV-FILE
              AT END SET END-OF-INV TO TRUE
           END-READ
           PERFORM UNTIL END-OF-INV
              PERFORM 3100-INSERT-BILL
              READ INV-FILE
                 AT END SET END-OF-INV TO TRUE
              END-READ
           END-PERFORM.

       3100-INSERT-BILL.
           MOVE IV-ID             TO HV-INVOICE-ID
           MOVE IV-RES            TO HV-BILL-RES-ID
           STRING IV-DATE (1:4) '-' IV-DATE (5:2) '-'
                  IV-DATE (7:2) DELIMITED BY SIZE INTO HV-BILL-DATE
           MOVE IV-NIGHTS         TO HV-NIGHTS
           MOVE IV-ROOM           TO HV-ROOM-CHARGE
           MOVE IV-SVC            TO HV-SERVICE-CHARGE
           MOVE IV-TAX            TO HV-TAX
           MOVE IV-TOT            TO HV-TOTAL
           MOVE IV-STATUS         TO HV-PAY-STATUS

           EXEC SQL
             INSERT INTO HRBS.BILL
               (INVOICE_ID, RES_ID, BILL_DATE, NIGHTS, ROOM_CHARGE,
                SERVICE_CHARGE, TAX, TOTAL, PAY_STATUS)
             VALUES
               (:HV-INVOICE-ID, :HV-BILL-RES-ID, DATE(:HV-BILL-DATE),
                :HV-NIGHTS, :HV-ROOM-CHARGE, :HV-SERVICE-CHARGE,
                :HV-TAX, :HV-TOTAL, :HV-PAY-STATUS)
           END-EXEC

           IF SQLCODE = 0
              ADD 1 TO WS-BILL-INS-CNT
              ADD 1 TO WS-PENDING-OPS
           ELSE
              IF SQLCODE = -803
                 ADD 1 TO WS-BILL-DUP-CNT
              ELSE
                 PERFORM 9999-SQL-ERROR
              END-IF
           END-IF

           IF WS-PENDING-OPS >= WS-COMMIT-FREQ
              EXEC SQL COMMIT WORK END-EXEC
              MOVE 0 TO WS-PENDING-OPS
           END-IF.

       4000-REPORT-UNPAID-BILLS.
           DISPLAY '=================================================='
           DISPLAY 'HRBSDB2 - UNPAID BILLS REPORT (VIA CURSOR C_UNPAID)'
           DISPLAY '=================================================='
           DISPLAY 'INVOICE ID  GUEST NAME                     AMOUNT'
           DISPLAY '--------------------------------------------------'

           EXEC SQL OPEN C_UNPAID END-EXEC
           IF SQLCODE NOT = 0
              PERFORM 9999-SQL-ERROR
           END-IF

           PERFORM 4100-FETCH-CURSOR
           PERFORM UNTIL END-OF-CURSOR
              MOVE HV-REP-TOTAL TO WS-DISPLAY-TOTAL
              DISPLAY HV-REP-INVID '    ' HV-REP-GNAME '   '
                      WS-DISPLAY-TOTAL
              ADD 1 TO WS-UNPAID-CNT
              PERFORM 4100-FETCH-CURSOR
           END-PERFORM

           EXEC SQL CLOSE C_UNPAID END-EXEC
           DISPLAY '--------------------------------------------------'
           DISPLAY 'TOTAL UNPAID INVOICES: ' WS-UNPAID-CNT
           DISPLAY '=================================================='.

       4100-FETCH-CURSOR.
           EXEC SQL
             FETCH C_UNPAID
              INTO :HV-REP-INVID, :HV-REP-GNAME, :HV-REP-TOTAL
           END-EXEC
           IF SQLCODE = 100
              SET END-OF-CURSOR TO TRUE
           ELSE
              IF SQLCODE NOT = 0
                 PERFORM 9999-SQL-ERROR
              END-IF
           END-IF.

       5000-CLOSE-FILES.
           CLOSE RESV-FILE INV-FILE
           DISPLAY '-------------------------------------------'
           DISPLAY 'HRBSDB2 - DB2 BATCH EXECUTION SUMMARY'
           DISPLAY 'RESERVATIONS INSERTED : ' WS-RESV-INS-CNT
           DISPLAY 'RESERVATIONS DUPLICATE: ' WS-RESV-DUP-CNT
           DISPLAY 'BILLS INSERTED        : ' WS-BILL-INS-CNT
           DISPLAY 'BILLS DUPLICATE       : ' WS-BILL-DUP-CNT
           DISPLAY '-------------------------------------------'.

       9999-SQL-ERROR.
           DISPLAY '*** HRBSDB2: DB2 SQL ERROR ***'
           DISPLAY 'SQLCODE  : ' SQLCODE
           DISPLAY 'SQLSTATE : ' SQLSTATE
           DISPLAY 'SQLERRMC : ' SQLERRMC
           EXEC SQL ROLLBACK WORK END-EXEC
           MOVE 12 TO RETURN-CODE
           STOP RUN.
