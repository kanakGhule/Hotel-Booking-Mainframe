       IDENTIFICATION DIVISION.
       PROGRAM-ID. HRBSMTCH.
      *****************************************************************
      * HOTEL RESERVATION AND BILLING SYSTEM (HRBS)
      * ASSIGNMENT 2 - MATCH RESERVATION FILE WITH PAYMENT FILE
      *   FILE1 : RESERVATIONS, 80 BYTES, KEY = COLS 13-20
      *   FILE2 : PAYMENTS,     80 BYTES, KEY = COLS 21-28
      *   FILE3 : MATCHED PAIRS, 160 BYTES = FILE1 REC + FILE2 REC
      * FILES NEED NOT BE SORTED (FILE2 IS LOADED INTO A TABLE).
      *****************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT RESV-FILE ASSIGN TO FILE1
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS1.
           SELECT PAY-FILE  ASSIGN TO FILE2
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS2.
           SELECT OUT-FILE  ASSIGN TO FILE3
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS3.

       DATA DIVISION.
       FILE SECTION.
       FD  RESV-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  RESV-REC.
           05 RV-HEAD             PIC X(12).
           05 RV-ID               PIC X(08).
           05 RV-TAIL             PIC X(60).

       FD  PAY-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  PAY-REC.
           05 PAY-HEAD            PIC X(20).
           05 PAY-RES-ID          PIC X(08).
           05 PAY-TAIL            PIC X(52).

       FD  OUT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  OUT-REC.
           05 OUT-RESV            PIC X(80).
           05 OUT-PAY             PIC X(80).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05 WS-FS1              PIC XX.
           05 WS-FS2              PIC XX.
           05 WS-FS3              PIC XX.
       01  WS-FLAGS.
           05 WS-EOF-RESV         PIC X VALUE 'N'.
              88 END-OF-RESV      VALUE 'Y'.
           05 WS-EOF-PAY          PIC X VALUE 'N'.
              88 END-OF-PAY       VALUE 'Y'.
           05 WS-FOUND            PIC X VALUE 'N'.
              88 FOUND-MATCH      VALUE 'Y'.
       01  WS-COUNTERS.
           05 WS-RESV-CNT         PIC 9(05) VALUE 0.
           05 WS-PAY-CNT          PIC 9(05) VALUE 0.
           05 WS-MATCH-CNT        PIC 9(05) VALUE 0.
           05 WS-NOMATCH-CNT      PIC 9(05) VALUE 0.
       01  WS-IX                  PIC 9(05) VALUE 0.
       01  PAY-TABLE.
           05 PAY-ENTRY OCCURS 100 TIMES.
              10 PT-KEY           PIC X(08).
              10 PT-REC           PIC X(80).

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-OPEN-FILES
           PERFORM 2000-LOAD-PAYMENTS
           PERFORM 3000-MATCH-RESERVATIONS
           PERFORM 4000-CLOSE-AND-REPORT
           STOP RUN.

       1000-OPEN-FILES.
           INITIALIZE PAY-TABLE
           OPEN INPUT  RESV-FILE
           OPEN INPUT  PAY-FILE
           OPEN OUTPUT OUT-FILE
           IF WS-FS1 NOT = '00' OR WS-FS2 NOT = '00'
              OR WS-FS3 NOT = '00'
              DISPLAY 'OPEN ERROR FS1=' WS-FS1 ' FS2=' WS-FS2
                      ' FS3=' WS-FS3
              MOVE 16 TO RETURN-CODE
              STOP RUN
           END-IF.

       2000-LOAD-PAYMENTS.
           PERFORM 2100-READ-PAY
           PERFORM UNTIL END-OF-PAY
              ADD 1 TO WS-PAY-CNT
              IF WS-PAY-CNT > 100
                 DISPLAY 'PAYMENT TABLE OVERFLOW - INCREASE OCCURS'
                 MOVE 16 TO RETURN-CODE
                 STOP RUN
              END-IF
              MOVE PAY-RES-ID TO PT-KEY (WS-PAY-CNT)
              MOVE PAY-REC    TO PT-REC (WS-PAY-CNT)
              PERFORM 2100-READ-PAY
           END-PERFORM.

       2100-READ-PAY.
           READ PAY-FILE
              AT END SET END-OF-PAY TO TRUE
           END-READ.

       3000-MATCH-RESERVATIONS.
           PERFORM 3100-READ-RESV
           PERFORM UNTIL END-OF-RESV
              ADD 1 TO WS-RESV-CNT
              MOVE 'N' TO WS-FOUND
              PERFORM VARYING WS-IX FROM 1 BY 1
                      UNTIL WS-IX > WS-PAY-CNT OR FOUND-MATCH
                 IF PT-KEY (WS-IX) = RV-ID
                    SET FOUND-MATCH TO TRUE
                    MOVE RESV-REC       TO OUT-RESV
                    MOVE PT-REC (WS-IX) TO OUT-PAY
                    WRITE OUT-REC
                    ADD 1 TO WS-MATCH-CNT
                 END-IF
              END-PERFORM
              IF NOT FOUND-MATCH
                 ADD 1 TO WS-NOMATCH-CNT
              END-IF
              PERFORM 3100-READ-RESV
           END-PERFORM.

       3100-READ-RESV.
           READ RESV-FILE
              AT END SET END-OF-RESV TO TRUE
           END-READ.

       4000-CLOSE-AND-REPORT.
           CLOSE RESV-FILE PAY-FILE OUT-FILE
           DISPLAY '-------------------------------------------'
           DISPLAY 'HRBSMTCH - RESERVATION/PAYMENT MATCH REPORT'
           DISPLAY 'FILE1 RECORDS READ     : ' WS-RESV-CNT
           DISPLAY 'FILE2 RECORDS LOADED   : ' WS-PAY-CNT
           DISPLAY 'MATCHED (WRITTEN FILE3): ' WS-MATCH-CNT
           DISPLAY 'FILE1 WITHOUT PAYMENT  : ' WS-NOMATCH-CNT
           DISPLAY '-------------------------------------------'.
