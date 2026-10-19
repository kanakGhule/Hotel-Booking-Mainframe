       IDENTIFICATION DIVISION.
       PROGRAM-ID. HRBSUPD.
      *****************************************************************
      * HOTEL RESERVATION AND BILLING SYSTEM (HRBS)
      * VSAM KSDS TRANSACTION UPDATE PROGRAM
      *
      * INPUT  (KSDSDD) : MASTER VSAM KSDS (RANDOM ACCESS, I-O)
      * INPUT  (TRNIN)  : TRANSACTION FILE (LRECL 80)
      * OUTPUT (AUDOUT) : AUDIT LOG FILE (LRECL 120)
      * OUTPUT (REJOUT) : REJECTED TRANSACTIONS (LRECL 120)
      *
      * TRANSACTION ACTIONS:
      *   'A' = ADD NEW RESERVATION (CHECKS DUPLICATE & OVERLAP)
      *   'C' = CANCEL RESERVATION (SETS STATUS 'X')
      *   'O' = CHECK-OUT GUEST (SETS STATUS 'O')
      *   'U' = UPDATE DATES / RATE
      *
      * ROOM AVAILABILITY APPROACH:
      *   AN IN-MEMORY TABLE (OCCURS 100) STORES ACTIVE BOOKINGS.
      *   ON 'A', CHECKS (NEW-IN < EXIST-OUT) AND (NEW-OUT > EXIST-IN)
      *   FOR THE SAME ROOM NUMBER.
      *
      * RETURN CODES:
      *   00 = ALL TRANSACTIONS PROCESSED SUCCESSFULLY
      *   04 = ONE OR MORE TRANSACTIONS REJECTED
      *   12 = FILE ERROR ON VSAM OR SEQUENTIAL FILES
      *****************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MAST-FILE ASSIGN TO KSDSDD
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS KS-ID
               FILE STATUS IS WS-FS-KSDS.
           SELECT TRN-FILE  ASSIGN TO TRNIN
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-TRN.
           SELECT AUD-FILE  ASSIGN TO AUDOUT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUD.
           SELECT REJ-FILE  ASSIGN TO REJOUT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJ.

       DATA DIVISION.
       FILE SECTION.
       FD  MAST-FILE.
       01  MAST-REC.
           05 KS-TYPE             PIC X(03).
           05 KS-HOTEL            PIC X(03).
           05 KS-BKDATE           PIC X(06).
           05 KS-ID               PIC X(08).
           05 KS-NAME             PIC X(20).
           05 KS-ROOM             PIC X(04).
           05 KS-RTYPE            PIC X(04).
           05 KS-CHKIN            PIC 9(08).
           05 KS-CHKOUT           PIC 9(08).
           05 KS-GUESTS           PIC 9(02).
           05 KS-RATE             PIC 9(06).
           05 KS-STATUS           PIC X(01).
           05 KS-FILLER           PIC X(07).

       FD  TRN-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  TRN-REC.
           05 TR-TYPE             PIC X(03).
           05 TR-ACTION           PIC X(01).
           05 TR-ID               PIC X(08).
           05 TR-NAME             PIC X(20).
           05 TR-ROOM             PIC X(04).
           05 TR-RTYPE            PIC X(04).
           05 TR-CHKIN            PIC 9(08).
           05 TR-CHKOUT           PIC 9(08).
           05 TR-GUESTS           PIC 9(02).
           05 TR-RATE             PIC 9(06).
           05 TR-STATUS           PIC X(01).
           05 TR-FILLER           PIC X(15).

       FD  AUD-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  AUD-REC.
           05 AU-DATE             PIC X(08).
           05 FILLER              PIC X(01) VALUE SPACE.
           05 AU-ACTION           PIC X(06).
           05 FILLER              PIC X(01) VALUE SPACE.
           05 AU-ID               PIC X(08).
           05 FILLER              PIC X(01) VALUE SPACE.
           05 AU-ROOM             PIC X(04).
           05 FILLER              PIC X(01) VALUE SPACE.
           05 AU-RESULT           PIC X(04).
           05 FILLER              PIC X(01) VALUE SPACE.
           05 AU-MESSAGE          PIC X(83).

       FD  REJ-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  REJ-REC.
           05 RJ-ORIG-TRN         PIC X(80).
           05 RJ-CODE             PIC X(02).
           05 RJ-REASON           PIC X(38).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05 WS-FS-KSDS          PIC XX VALUE '00'.
           05 WS-FS-TRN           PIC XX VALUE '00'.
           05 WS-FS-AUD           PIC XX VALUE '00'.
           05 WS-FS-REJ           PIC XX VALUE '00'.

       01  WS-FLAGS.
           05 WS-EOF-TRN          PIC X VALUE 'N'.
              88 END-OF-TRN       VALUE 'Y'.
           05 WS-OVERLAP-FOUND    PIC X VALUE 'N'.
              88 HAS-OVERLAP      VALUE 'Y'.

       01  WS-COUNTERS.
           05 WS-TRN-READ         PIC 9(05) VALUE 0.
           05 WS-ADD-CNT          PIC 9(05) VALUE 0.
           05 WS-CAN-CNT          PIC 9(05) VALUE 0.
           05 WS-OUT-CNT          PIC 9(05) VALUE 0.
           05 WS-UPD-CNT          PIC 9(05) VALUE 0.
           05 WS-REJ-CNT          PIC 9(05) VALUE 0.

      *---- PARAMETER PASSING FIELDS FOR AUDIT AND REJECT ------------*
       01  WS-AUD-FIELDS.
           05 WS-AUD-ACT          PIC X(06) VALUE SPACES.
           05 WS-AUD-RES          PIC X(04) VALUE SPACES.
           05 WS-AUD-MSG          PIC X(83) VALUE SPACES.

       01  WS-REJ-FIELDS.
           05 WS-REJ-CODE         PIC X(02) VALUE SPACES.
           05 WS-REJ-MSG          PIC X(38) VALUE SPACES.

      *---- IN-MEMORY ACTIVE BOOKINGS FOR ROOM OVERLAP DETECTION -----*
       01  WS-BOOKING-TABLE.
           05 BT-COUNT            PIC 9(04) VALUE 0.
           05 BT-ENTRY OCCURS 100 TIMES INDEXED BY BT-IDX.
              10 BT-ROOM          PIC X(04).
              10 BT-CHKIN         PIC 9(08).
              10 BT-CHKOUT        PIC 9(08).
              10 BT-STATUS        PIC X(01).

       01  WS-TODAY               PIC X(08).

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-OPEN-FILES
           PERFORM 2000-PROCESS-TRANS UNTIL END-OF-TRN
           PERFORM 3000-CLOSE-AND-REPORT
           IF WS-REJ-CNT > 0
              MOVE 4 TO RETURN-CODE
           ELSE
              MOVE 0 TO RETURN-CODE
           END-IF
           STOP RUN.

       1000-OPEN-FILES.
           MOVE FUNCTION CURRENT-DATE (1:8) TO WS-TODAY
           OPEN I-O MAST-FILE
           IF WS-FS-KSDS NOT = '00'
              DISPLAY 'HRBSUPD: VSAM OPEN ERROR FS=' WS-FS-KSDS
              MOVE 12 TO RETURN-CODE
              STOP RUN
           END-IF

           OPEN INPUT  TRN-FILE
           OPEN OUTPUT AUD-FILE
           OPEN OUTPUT REJ-FILE
           IF WS-FS-TRN NOT = '00' OR WS-FS-AUD NOT = '00'
              OR WS-FS-REJ NOT = '00'
              DISPLAY 'HRBSUPD: SEQ OPEN ERROR TRN=' WS-FS-TRN
                      ' AUD=' WS-FS-AUD ' REJ=' WS-FS-REJ
              MOVE 12 TO RETURN-CODE
              STOP RUN
           END-IF

           PERFORM 1100-READ-TRN.

       1100-READ-TRN.
           READ TRN-FILE
              AT END SET END-OF-TRN TO TRUE
              NOT AT END ADD 1 TO WS-TRN-READ
           END-READ.

       2000-PROCESS-TRANS.
           EVALUATE TR-ACTION
              WHEN 'A'
                 PERFORM 2100-HANDLE-ADD
              WHEN 'C'
                 PERFORM 2200-HANDLE-CANCEL
              WHEN 'O'
                 PERFORM 2300-HANDLE-CHECKOUT
              WHEN 'U'
                 PERFORM 2400-HANDLE-UPDATE
              WHEN OTHER
                 PERFORM 2900-HANDLE-INVALID-ACTION
           END-EVALUATE
           PERFORM 1100-READ-TRN.

       2100-HANDLE-ADD.
      *---- CHECK IF KEY ALREADY EXISTS IN KSDS ----------------------*
           MOVE TR-ID TO KS-ID
           READ MAST-FILE
           IF WS-FS-KSDS = '00'
              MOVE '22' TO WS-REJ-CODE
              MOVE 'DUPLICATE KEY - RESERVATION EXISTS    '
                TO WS-REJ-MSG
              PERFORM 2800-REJECT-TRANS
           ELSE
      *---- CHECK ROOM OVERLAP ---------------------------------------*
              PERFORM 2500-CHECK-ROOM-AVAILABILITY
              IF HAS-OVERLAP
                 MOVE 'RO' TO WS-REJ-CODE
                 MOVE 'ROOM NOT AVAILABLE - OVERLAPPING DATES '
                   TO WS-REJ-MSG
                 PERFORM 2800-REJECT-TRANS
              ELSE
                 PERFORM 2150-EXECUTE-ADD
              END-IF
           END-IF.

       2150-EXECUTE-ADD.
           MOVE SPACES         TO MAST-REC
           MOVE 'RSV'          TO KS-TYPE
           MOVE 'PUN'          TO KS-HOTEL
           MOVE WS-TODAY (3:6) TO KS-BKDATE
           MOVE TR-ID          TO KS-ID
           MOVE TR-NAME        TO KS-NAME
           MOVE TR-ROOM        TO KS-ROOM
           MOVE TR-RTYPE       TO KS-RTYPE
           MOVE TR-CHKIN       TO KS-CHKIN
           MOVE TR-CHKOUT      TO KS-CHKOUT
           MOVE TR-GUESTS      TO KS-GUESTS
           MOVE TR-RATE        TO KS-RATE
           MOVE 'C'            TO KS-STATUS
           MOVE SPACES         TO KS-FILLER

           WRITE MAST-REC
           IF WS-FS-KSDS = '00'
              ADD 1 TO WS-ADD-CNT
              MOVE 'ADD   '                       TO WS-AUD-ACT
              MOVE 'OK  '                         TO WS-AUD-RES
              MOVE 'RESERVATION ADDED SUCCESSFULLY' TO WS-AUD-MSG
              PERFORM 2700-WRITE-AUDIT
              IF BT-COUNT < 100
                 ADD 1 TO BT-COUNT
                 MOVE TR-ROOM   TO BT-ROOM (BT-COUNT)
                 MOVE TR-CHKIN  TO BT-CHKIN (BT-COUNT)
                 MOVE TR-CHKOUT TO BT-CHKOUT (BT-COUNT)
                 MOVE 'C'       TO BT-STATUS (BT-COUNT)
              END-IF
           ELSE
              MOVE WS-FS-KSDS TO WS-REJ-CODE
              MOVE 'VSAM WRITE FAILED                     '
                TO WS-REJ-MSG
              PERFORM 2800-REJECT-TRANS
           END-IF.

       2200-HANDLE-CANCEL.
           MOVE TR-ID TO KS-ID
           READ MAST-FILE
           IF WS-FS-KSDS = '23'
              MOVE '23' TO WS-REJ-CODE
              MOVE 'RESERVATION NOT FOUND FOR CANCELLATION'
                TO WS-REJ-MSG
              PERFORM 2800-REJECT-TRANS
           ELSE
              IF WS-FS-KSDS = '00'
                 MOVE 'X' TO KS-STATUS
                 REWRITE MAST-REC
                 IF WS-FS-KSDS = '00'
                    ADD 1 TO WS-CAN-CNT
                    MOVE 'CANCEL'                 TO WS-AUD-ACT
                    MOVE 'OK  '                   TO WS-AUD-RES
                    MOVE 'RESERVATION CANCELLED   ' TO WS-AUD-MSG
                    PERFORM 2700-WRITE-AUDIT
                 ELSE
                    MOVE WS-FS-KSDS TO WS-REJ-CODE
                    MOVE 'VSAM REWRITE FAILED                   '
                      TO WS-REJ-MSG
                    PERFORM 2800-REJECT-TRANS
                 END-IF
              ELSE
                 MOVE WS-FS-KSDS TO WS-REJ-CODE
                 MOVE 'VSAM READ ERROR                       '
                   TO WS-REJ-MSG
                 PERFORM 2800-REJECT-TRANS
              END-IF
           END-IF.

       2300-HANDLE-CHECKOUT.
           MOVE TR-ID TO KS-ID
           READ MAST-FILE
           IF WS-FS-KSDS = '23'
              MOVE '23' TO WS-REJ-CODE
              MOVE 'RESERVATION NOT FOUND FOR CHECK-OUT   '
                TO WS-REJ-MSG
              PERFORM 2800-REJECT-TRANS
           ELSE
              IF WS-FS-KSDS = '00'
                 MOVE 'O' TO KS-STATUS
                 REWRITE MAST-REC
                 IF WS-FS-KSDS = '00'
                    ADD 1 TO WS-OUT-CNT
                    MOVE 'CHKOUT'                 TO WS-AUD-ACT
                    MOVE 'OK  '                   TO WS-AUD-RES
                    MOVE 'GUEST CHECKED OUT       ' TO WS-AUD-MSG
                    PERFORM 2700-WRITE-AUDIT
                 ELSE
                    MOVE WS-FS-KSDS TO WS-REJ-CODE
                    MOVE 'VSAM REWRITE FAILED                   '
                      TO WS-REJ-MSG
                    PERFORM 2800-REJECT-TRANS
                 END-IF
              ELSE
                 MOVE WS-FS-KSDS TO WS-REJ-CODE
                 MOVE 'VSAM READ ERROR                       '
                   TO WS-REJ-MSG
                 PERFORM 2800-REJECT-TRANS
              END-IF
           END-IF.

       2400-HANDLE-UPDATE.
           MOVE TR-ID TO KS-ID
           READ MAST-FILE
           IF WS-FS-KSDS = '23'
              MOVE '23' TO WS-REJ-CODE
              MOVE 'RESERVATION NOT FOUND FOR UPDATE      '
                TO WS-REJ-MSG
              PERFORM 2800-REJECT-TRANS
           ELSE
              IF WS-FS-KSDS = '00'
                 IF TR-RATE > 0
                    MOVE TR-RATE TO KS-RATE
                 END-IF
                 IF TR-CHKIN > 0
                    MOVE TR-CHKIN TO KS-CHKIN
                 END-IF
                 IF TR-CHKOUT > 0
                    MOVE TR-CHKOUT TO KS-CHKOUT
                 END-IF
                 REWRITE MAST-REC
                 IF WS-FS-KSDS = '00'
                    ADD 1 TO WS-UPD-CNT
                    MOVE 'UPDATE'                 TO WS-AUD-ACT
                    MOVE 'OK  '                   TO WS-AUD-RES
                    MOVE 'RESERVATION DETAILS UPDATED'
                      TO WS-AUD-MSG
                    PERFORM 2700-WRITE-AUDIT
                 ELSE
                    MOVE WS-FS-KSDS TO WS-REJ-CODE
                    MOVE 'VSAM REWRITE FAILED                   '
                      TO WS-REJ-MSG
                    PERFORM 2800-REJECT-TRANS
                 END-IF
              ELSE
                 MOVE WS-FS-KSDS TO WS-REJ-CODE
                 MOVE 'VSAM READ ERROR                       '
                   TO WS-REJ-MSG
                 PERFORM 2800-REJECT-TRANS
              END-IF
           END-IF.

       2500-CHECK-ROOM-AVAILABILITY.
           MOVE 'N' TO WS-OVERLAP-FOUND
           IF BT-COUNT > 0
              PERFORM VARYING BT-IDX FROM 1 BY 1
                      UNTIL BT-IDX > BT-COUNT OR HAS-OVERLAP
                 IF BT-ROOM (BT-IDX) = TR-ROOM
                    AND BT-STATUS (BT-IDX) NOT = 'X'
                    IF TR-CHKIN < BT-CHKOUT (BT-IDX)
                       AND TR-CHKOUT > BT-CHKIN (BT-IDX)
                       SET HAS-OVERLAP TO TRUE
                    END-IF
                 END-IF
              END-PERFORM
           END-IF.

       2700-WRITE-AUDIT.
           MOVE WS-TODAY   TO AU-DATE
           MOVE WS-AUD-ACT TO AU-ACTION
           MOVE TR-ID      TO AU-ID
           MOVE TR-ROOM    TO AU-ROOM
           MOVE WS-AUD-RES TO AU-RESULT
           MOVE WS-AUD-MSG TO AU-MESSAGE
           WRITE AUD-REC.

       2800-REJECT-TRANS.
           MOVE TRN-REC    TO RJ-ORIG-TRN
           MOVE WS-REJ-CODE TO RJ-CODE
           MOVE WS-REJ-MSG  TO RJ-REASON
           WRITE REJ-REC
           ADD 1 TO WS-REJ-CNT
           MOVE 'REJ   '   TO WS-AUD-ACT
           MOVE 'FAIL'     TO WS-AUD-RES
           MOVE WS-REJ-MSG TO WS-AUD-MSG
           PERFORM 2700-WRITE-AUDIT.

       2900-HANDLE-INVALID-ACTION.
           MOVE '99' TO WS-REJ-CODE
           MOVE 'INVALID TRANSACTION ACTION CODE       '
             TO WS-REJ-MSG
           PERFORM 2800-REJECT-TRANS.

       3000-CLOSE-AND-REPORT.
           CLOSE MAST-FILE TRN-FILE AUD-FILE REJ-FILE
           DISPLAY '-------------------------------------------'
           DISPLAY 'HRBSUPD - VSAM TRANSACTION UPDATE SUMMARY'
           DISPLAY 'TRANSACTIONS READ   : ' WS-TRN-READ
           DISPLAY 'ADDS PROCESSED      : ' WS-ADD-CNT
           DISPLAY 'CANCELS PROCESSED   : ' WS-CAN-CNT
           DISPLAY 'CHECK-OUTS PROCESSED: ' WS-OUT-CNT
           DISPLAY 'UPDATES PROCESSED   : ' WS-UPD-CNT
           DISPLAY 'REJECTED TRANS      : ' WS-REJ-CNT
           DISPLAY '-------------------------------------------'.
