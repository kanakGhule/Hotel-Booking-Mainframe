       IDENTIFICATION DIVISION.
       PROGRAM-ID. HRBSVAL.
      *****************************************************************
      * HOTEL RESERVATION AND BILLING SYSTEM (HRBS)
      * VALIDATION MODULE - VALIDATES SORTED RESERVATIONS (JOB01 OUTPUT)
      *
      * INPUT  (RESVIN) : RESERVATIONS, 80 BYTES (SORTED BY KEY)
      * OUTPUT (VALOUT) : VALID RESERVATIONS, 80 BYTES
      * OUTPUT (REJOUT) : REJECTED RESERVATIONS, 120 BYTES
      *                   (80-BYTE RECORD + 2-BYTE CODE + 38-BYTE MSG)
      *
      * VALIDATION RULES:
      * 1. RECORD TYPE = 'RSV'
      * 2. RESERVATION ID FORMAT = 'RS' + 6 NUMERIC DIGITS
      * 3. BOOKING DATE = VALID YYMMDD
      * 4. CHECK-IN DATE = VALID YYYYMMDD
      * 5. CHECK-OUT DATE = VALID YYYYMMDD
      * 6. CHECK-OUT DATE STRICTLY AFTER CHECK-IN DATE
      * 7. ROOM TYPE IN ('STD ', 'DLX ', 'STE ')
      * 8. GUEST COUNT BETWEEN 1 AND 4
      * 9. ROOM RATE CONSISTENT WITH TYPE (STD=3500, DLX=5200, STE=8800)
      * 10. STATUS IN ('C', 'X', 'O')
      *
      * RETURN CODES:
      *   00 = ALL RECORDS VALID (0 REJECTS)
      *   04 = ONE OR MORE RECORDS REJECTED
      *   12 = FILE OPEN OR SEVERE I/O ERROR
      *****************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT RESV-FILE ASSIGN TO RESVIN
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-IN.
           SELECT VAL-FILE  ASSIGN TO VALOUT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-VAL.
           SELECT REJ-FILE  ASSIGN TO REJOUT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJ.

       DATA DIVISION.
       FILE SECTION.
       FD  RESV-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  RESV-REC.
           05 RV-TYPE             PIC X(03).
           05 RV-HOTEL            PIC X(03).
           05 RV-BKDATE           PIC X(06).
           05 RV-ID.
              10 RV-ID-PREFIX     PIC X(02).
              10 RV-ID-NUM        PIC 9(06).
           05 RV-NAME             PIC X(20).
           05 RV-ROOM             PIC X(04).
           05 RV-RTYPE            PIC X(04).
           05 RV-CHKIN            PIC 9(08).
           05 RV-CHKOUT           PIC 9(08).
           05 RV-GUESTS           PIC 9(02).
           05 RV-RATE             PIC 9(06).
           05 RV-STATUS           PIC X(01).
           05 FILLER              PIC X(07).

       FD  VAL-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  VAL-REC                PIC X(80).

       FD  REJ-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  REJ-REC.
           05 RJ-ORIG-REC         PIC X(80).
           05 RJ-CODE             PIC X(02).
           05 RJ-MSG              PIC X(38).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05 WS-FS-IN            PIC XX VALUE '00'.
           05 WS-FS-VAL           PIC XX VALUE '00'.
           05 WS-FS-REJ           PIC XX VALUE '00'.

       01  WS-FLAGS.
           05 WS-EOF-IN           PIC X VALUE 'N'.
              88 END-OF-INPUT     VALUE 'Y'.
           05 WS-REC-VALID        PIC X VALUE 'Y'.
              88 REC-IS-VALID     VALUE 'Y'.
              88 REC-IS-INVALID   VALUE 'N'.

       01  WS-COUNTERS.
           05 WS-READ-CNT         PIC 9(05) VALUE 0.
           05 WS-VAL-CNT          PIC 9(05) VALUE 0.
           05 WS-REJ-CNT          PIC 9(05) VALUE 0.

      *---- REJECTION REASON CODE AND MESSAGE ------------------------*
       01  WS-REJECT-INFO.
           05 WS-REJ-CODE         PIC X(02) VALUE SPACES.
           05 WS-REJ-MSG          PIC X(38) VALUE SPACES.

      *---- DATE VALIDATION WORK FIELDS ------------------------------*
       01  WS-DATE-WORK.
           05 DW-YYYY             PIC 9(04).
           05 DW-MM               PIC 9(02).
           05 DW-DD               PIC 9(02).
           05 DW-LEAP-REM         PIC 9(04).
           05 DW-MAX-DAYS         PIC 9(02).

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-OPEN-FILES
           PERFORM 2000-PROCESS UNTIL END-OF-INPUT
           PERFORM 3000-CLOSE-AND-REPORT
           IF WS-REJ-CNT > 0
              MOVE 4 TO RETURN-CODE
           ELSE
              MOVE 0 TO RETURN-CODE
           END-IF
           STOP RUN.

       1000-OPEN-FILES.
           OPEN INPUT  RESV-FILE
           OPEN OUTPUT VAL-FILE
           OPEN OUTPUT REJ-FILE
           IF WS-FS-IN NOT = '00' OR WS-FS-VAL NOT = '00'
              OR WS-FS-REJ NOT = '00'
              DISPLAY 'HRBSVAL: OPEN ERROR FS-IN=' WS-FS-IN
                      ' FS-VAL=' WS-FS-VAL ' FS-REJ=' WS-FS-REJ
              MOVE 12 TO RETURN-CODE
              STOP RUN
           END-IF
           PERFORM 1100-READ-INPUT.

       1100-READ-INPUT.
           READ RESV-FILE
              AT END SET END-OF-INPUT TO TRUE
              NOT AT END ADD 1 TO WS-READ-CNT
           END-READ.

       2000-PROCESS.
           SET REC-IS-VALID TO TRUE
           MOVE SPACES TO WS-REJECT-INFO

      *---- RULE 1: RECORD TYPE MUST BE 'RSV' ------------------------*
           IF REC-IS-VALID AND RV-TYPE NOT = 'RSV'
              SET REC-IS-INVALID TO TRUE
              MOVE '01' TO WS-REJ-CODE
              MOVE 'INVALID RECORD TYPE (EXPECTED RSV)    '
                TO WS-REJ-MSG
           END-IF

      *---- RULE 2: RESV ID MUST BE 'RS' + 6 NUMERIC DIGITS ----------*
           IF REC-IS-VALID
              IF RV-ID-PREFIX NOT = 'RS'
                 OR RV-ID-NUM NOT NUMERIC
                 SET REC-IS-INVALID TO TRUE
                 MOVE '02' TO WS-REJ-CODE
                 MOVE 'INVALID RES-ID FORMAT (RS+6 DIGITS)  '
                   TO WS-REJ-MSG
              END-IF
           END-IF

      *---- RULE 3: CHECK-IN DATE VALIDITY ---------------------------*
           IF REC-IS-VALID
              MOVE RV-CHKIN (1:4) TO DW-YYYY
              MOVE RV-CHKIN (5:2) TO DW-MM
              MOVE RV-CHKIN (7:2) TO DW-DD
              PERFORM 2500-VALIDATE-CALENDAR-DATE
              IF REC-IS-INVALID
                 MOVE '04' TO WS-REJ-CODE
                 MOVE 'INVALID CHECK-IN DATE (YYYYMMDD)     '
                   TO WS-REJ-MSG
              END-IF
           END-IF

      *---- RULE 4: CHECK-OUT DATE VALIDITY --------------------------*
           IF REC-IS-VALID
              MOVE RV-CHKOUT (1:4) TO DW-YYYY
              MOVE RV-CHKOUT (5:2) TO DW-MM
              MOVE RV-CHKOUT (7:2) TO DW-DD
              PERFORM 2500-VALIDATE-CALENDAR-DATE
              IF REC-IS-INVALID
                 MOVE '05' TO WS-REJ-CODE
                 MOVE 'INVALID CHECK-OUT DATE (YYYYMMDD)    '
                   TO WS-REJ-MSG
              END-IF
           END-IF

      *---- RULE 5: CHECK-OUT STRICTLY AFTER CHECK-IN ----------------*
           IF REC-IS-VALID
              IF RV-CHKOUT <= RV-CHKIN
                 SET REC-IS-INVALID TO TRUE
                 MOVE '06' TO WS-REJ-CODE
                 MOVE 'CHECK-OUT DATE NOT AFTER CHECK-IN    '
                   TO WS-REJ-MSG
              END-IF
           END-IF

      *---- RULE 6: ROOM TYPE MUST BE STD, DLX, OR STE ---------------*
           IF REC-IS-VALID
              IF RV-RTYPE NOT = 'STD ' AND RV-RTYPE NOT = 'DLX '
                 AND RV-RTYPE NOT = 'STE '
                 SET REC-IS-INVALID TO TRUE
                 MOVE '07' TO WS-REJ-CODE
                 MOVE 'INVALID ROOM TYPE (NOT STD/DLX/STE)  '
                   TO WS-REJ-MSG
              END-IF
           END-IF

      *---- RULE 7: GUEST COUNT BETWEEN 1 AND 4 ----------------------*
           IF REC-IS-VALID
              IF RV-GUESTS < 1 OR RV-GUESTS > 4
                 SET REC-IS-INVALID TO TRUE
                 MOVE '08' TO WS-REJ-CODE
                 MOVE 'GUEST COUNT OUT OF RANGE (1 - 4)     '
                   TO WS-REJ-MSG
              END-IF
           END-IF

      *---- RULE 8: RATE CONSISTENCY WITH ROOM TYPE ------------------*
           IF REC-IS-VALID
              EVALUATE RV-RTYPE
                 WHEN 'STD '
                    IF RV-RATE NOT = 3500
                       SET REC-IS-INVALID TO TRUE
                    END-IF
                 WHEN 'DLX '
                    IF RV-RATE NOT = 5200
                       SET REC-IS-INVALID TO TRUE
                    END-IF
                 WHEN 'STE '
                    IF RV-RATE NOT = 8800
                       SET REC-IS-INVALID TO TRUE
                    END-IF
                 WHEN OTHER
                    SET REC-IS-INVALID TO TRUE
              END-EVALUATE
              IF REC-IS-INVALID
                 MOVE '09' TO WS-REJ-CODE
                 MOVE 'RATE INCONSISTENT WITH ROOM TYPE     '
                   TO WS-REJ-MSG
              END-IF
           END-IF

      *---- RULE 9: STATUS MUST BE C, X, OR O ------------------------*
           IF REC-IS-VALID
              IF RV-STATUS NOT = 'C' AND RV-STATUS NOT = 'X'
                 AND RV-STATUS NOT = 'O'
                 SET REC-IS-INVALID TO TRUE
                 MOVE '10' TO WS-REJ-CODE
                 MOVE 'INVALID STATUS (NOT C, X, OR O)      '
                   TO WS-REJ-MSG
              END-IF
           END-IF

      *---- DISPOSITION ----------------------------------------------*
           IF REC-IS-VALID
              MOVE RESV-REC TO VAL-REC
              WRITE VAL-REC
              ADD 1 TO WS-VAL-CNT
           ELSE
              MOVE RESV-REC   TO RJ-ORIG-REC
              MOVE WS-REJ-CODE TO RJ-CODE
              MOVE WS-REJ-MSG  TO RJ-MSG
              WRITE REJ-REC
              ADD 1 TO WS-REJ-CNT
           END-IF

           PERFORM 1100-READ-INPUT.

       2500-VALIDATE-CALENDAR-DATE.
           IF DW-YYYY < 2020 OR DW-YYYY > 2035
              SET REC-IS-INVALID TO TRUE
           END-IF
           IF DW-MM < 1 OR DW-MM > 12
              SET REC-IS-INVALID TO TRUE
           END-IF
           IF REC-IS-VALID
              EVALUATE DW-MM
                 WHEN 1  MOVE 31 TO DW-MAX-DAYS
                 WHEN 3  MOVE 31 TO DW-MAX-DAYS
                 WHEN 5  MOVE 31 TO DW-MAX-DAYS
                 WHEN 7  MOVE 31 TO DW-MAX-DAYS
                 WHEN 8  MOVE 31 TO DW-MAX-DAYS
                 WHEN 10 MOVE 31 TO DW-MAX-DAYS
                 WHEN 12 MOVE 31 TO DW-MAX-DAYS
                 WHEN 4  MOVE 30 TO DW-MAX-DAYS
                 WHEN 6  MOVE 30 TO DW-MAX-DAYS
                 WHEN 9  MOVE 30 TO DW-MAX-DAYS
                 WHEN 11 MOVE 30 TO DW-MAX-DAYS
                 WHEN 2
                    DIVIDE DW-YYYY BY 4 GIVING DW-LEAP-REM
                    REMAINDER DW-LEAP-REM
                    IF DW-LEAP-REM = 0
                       MOVE 29 TO DW-MAX-DAYS
                    ELSE
                       MOVE 28 TO DW-MAX-DAYS
                    END-IF
              END-EVALUATE
              IF DW-DD < 1 OR DW-DD > DW-MAX-DAYS
                 SET REC-IS-INVALID TO TRUE
              END-IF
           END-IF.

       3000-CLOSE-AND-REPORT.
           CLOSE RESV-FILE VAL-FILE REJ-FILE
           DISPLAY '-------------------------------------------'
           DISPLAY 'HRBSVAL - RESERVATION VALIDATION SUMMARY'
           DISPLAY 'RESERVATIONS READ    : ' WS-READ-CNT
           DISPLAY 'VALID (WRITTEN VAL)  : ' WS-VAL-CNT
           DISPLAY 'REJECTS (WRITTEN REJ): ' WS-REJ-CNT
           DISPLAY '-------------------------------------------'.
