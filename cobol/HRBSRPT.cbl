       IDENTIFICATION DIVISION.
       PROGRAM-ID. HRBSRPT.
      *****************************************************************
      * HOTEL RESERVATION AND BILLING SYSTEM (HRBS)
      * BILLING REPORT GENERATION MODULE (132-COLUMN PRINTED REPORT)
      *
      * INPUT  (INFILE) : INVOICES SORTED BY ROOM TYPE & INVOICE ID
      *                   (LRECL 104 OR 100)
      * OUTPUT (RPTFILE): 132-COLUMN FORMATTED REPORT
      *
      * FEATURES:
      * 1. REPORT HEADINGS WITH DATE AND AUTO-INCREMENTING PAGE NUMBER.
      * 2. DETAIL PRINT LINES FORMATTED WITH EDIT MASKS.
      * 3. PAGE OVERFLOW HANDLING: MAX 55 LINES PER PAGE.
      * 4. CONTROL BREAK ON ROOM TYPE WITH SUB-TOTALS.
      * 5. GRAND TOTAL ACCUMULATOR AT REPORT CONCLUSION.
      *
      * RETURN CODES:
      *   00 = REPORT GENERATED SUCCESSFULLY
      *   12 = FILE OPEN OR WRITE ERROR
      *****************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE   ASSIGN TO INFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-IN.
           SELECT RPT-FILE  ASSIGN TO RPTFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-RPT.

       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  IN-REC.
           05 IR-TYPE             PIC X(03).
           05 IR-HOTEL            PIC X(03).
           05 IR-DATE             PIC X(08).
           05 IR-GUEST            PIC X(10).
           05 IR-ID               PIC X(08).
           05 IR-RES              PIC X(08).
           05 IR-NAME             PIC X(20).
           05 IR-NIGHTS           PIC 9(03).
           05 IR-ROOM             PIC 9(06)V99.
           05 IR-SVC              PIC 9(06)V99.
           05 IR-TAX              PIC 9(06)V99.
           05 IR-TOT              PIC 9(08)V99.
           05 IR-STATUS           PIC X(01).
           05 IR-FILLER           PIC X(02).
           05 IR-RTYPE-EXT        PIC X(04).

       FD  RPT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  RPT-REC                PIC X(132).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05 WS-FS-IN            PIC XX VALUE '00'.
           05 WS-FS-RPT           PIC XX VALUE '00'.

       01  WS-FLAGS.
           05 WS-EOF-IN           PIC X VALUE 'N'.
              88 END-OF-FILE      VALUE 'Y'.
           05 WS-FIRST-REC        PIC X VALUE 'Y'.
              88 FIRST-RECORD     VALUE 'Y'.

       01  WS-PAGE-INFO.
           05 WS-PAGE-NUM         PIC 9(04) VALUE 0.
           05 WS-LINE-COUNT       PIC 9(02) VALUE 60.
           05 WS-MAX-LINES        PIC 9(02) VALUE 50.
           05 WS-TODAY            PIC X(10).

      *---- CONTROL BREAK VARIABLES ----------------------------------*
       01  WS-CURRENT-RTYPE       PIC X(04) VALUE SPACES.
       01  WS-PREV-RTYPE          PIC X(04) VALUE SPACES.

      *---- SUB-TOTAL ACCUMULATORS (ROOM TYPE BREAK) -----------------*
       01  WS-SUB-TOTALS.
           05 SUB-COUNT           PIC 9(05) VALUE 0.
           05 SUB-ROOM            PIC 9(09)V99 VALUE 0.
           05 SUB-SVC             PIC 9(09)V99 VALUE 0.
           05 SUB-TAX             PIC 9(09)V99 VALUE 0.
           05 SUB-TOT             PIC 9(10)V99 VALUE 0.

      *---- GRAND TOTAL ACCUMULATORS ---------------------------------*
       01  WS-GRAND-TOTALS.
           05 GRD-COUNT           PIC 9(06) VALUE 0.
           05 GRD-ROOM            PIC 9(10)V99 VALUE 0.
           05 GRD-SVC             PIC 9(10)V99 VALUE 0.
           05 GRD-TAX             PIC 9(10)V99 VALUE 0.
           05 GRD-TOT             PIC 9(11)V99 VALUE 0.

      *---- PRINT LINE DEFINITIONS (132 CHARACTERS) ------------------*
       01  HDG-LINE-1.
           05 FILLER              PIC X(06) VALUE 'DATE: '.
           05 H1-DATE             PIC X(10).
           05 FILLER              PIC X(15) VALUE SPACES.
           05 FILLER              PIC X(45) VALUE
              'HOTEL RESERVATION AND BILLING SYSTEM (HRBS)  '.
           05 FILLER              PIC X(45) VALUE SPACES.
           05 FILLER              PIC X(06) VALUE 'PAGE: '.
           05 H1-PAGE             PIC Z,ZZ9.

       01  HDG-LINE-2.
           05 FILLER              PIC X(50) VALUE SPACES.
           05 FILLER              PIC X(32) VALUE
              'COMPREHENSIVE BILLING REPORT    '.
           05 FILLER              PIC X(50) VALUE SPACES.

       01  DIVIDER-DOUBLE.
           05 FILLER              PIC X(132) VALUE ALL '='.

       01  DIVIDER-SINGLE.
           05 FILLER              PIC X(132) VALUE ALL '-'.

       01  COL-HEADINGS.
           05 FILLER              PIC X(10) VALUE 'INV ID    '.
           05 FILLER              PIC X(12) VALUE 'GUEST ID    '.
           05 FILLER          PIC X(22) VALUE 'GUEST NAME            '.
           05 FILLER              PIC X(10) VALUE 'RESV ID   '.
           05 FILLER              PIC X(06) VALUE 'TYPE  '.
           05 FILLER              PIC X(05) VALUE 'NTS  '.
           05 FILLER              PIC X(14) VALUE '  ROOM CHARGES'.
           05 FILLER              PIC X(14) VALUE '   SERVICE CHG'.
           05 FILLER              PIC X(14) VALUE '       GST TAX'.
           05 FILLER              PIC X(16) VALUE '  TOTAL AMOUNT  '.
           05 FILLER              PIC X(09) VALUE 'STATUS   '.

       01  DETAIL-LINE.
           05 DT-INVID            PIC X(08).
           05 FILLER              PIC X(02) VALUE SPACES.
           05 DT-GUESTID          PIC X(10).
           05 FILLER              PIC X(02) VALUE SPACES.
           05 DT-NAME             PIC X(20).
           05 FILLER              PIC X(02) VALUE SPACES.
           05 DT-RESVID           PIC X(08).
           05 FILLER              PIC X(02) VALUE SPACES.
           05 DT-RTYPE            PIC X(04).
           05 FILLER              PIC X(02) VALUE SPACES.
           05 DT-NIGHTS           PIC ZZ9.
           05 FILLER              PIC X(02) VALUE SPACES.
           05 DT-ROOM             PIC ZZZ,ZZ9.99.
           05 FILLER              PIC X(02) VALUE SPACES.
           05 DT-SVC              PIC ZZZ,ZZ9.99.
           05 FILLER              PIC X(02) VALUE SPACES.
           05 DT-TAX              PIC ZZZ,ZZ9.99.
           05 FILLER              PIC X(02) VALUE SPACES.
           05 DT-TOT              PIC Z,ZZZ,ZZ9.99.
           05 FILLER              PIC X(03) VALUE SPACES.
           05 DT-STATUS           PIC X(06).

       01  SUBTOTAL-LINE.
           05 FILLER              PIC X(26) VALUE
              '* SUB-TOTAL FOR ROOM TYPE: '.
           05 ST-RTYPE            PIC X(04).
           05 FILLER              PIC X(13) VALUE ' (BOOKINGS:  '.
           05 ST-COUNT            PIC ZZ,ZZ9.
           05 FILLER              PIC X(14) VALUE ')             '.
           05 ST-ROOM             PIC Z,ZZZ,ZZ9.99.
           05 FILLER              PIC X(02) VALUE SPACES.
           05 ST-SVC              PIC Z,ZZZ,ZZ9.99.
           05 FILLER              PIC X(02) VALUE SPACES.
           05 ST-TAX              PIC Z,ZZZ,ZZ9.99.
           05 FILLER              PIC X(02) VALUE SPACES.
           05 ST-TOT              PIC ZZ,ZZZ,ZZ9.99.
           05 FILLER              PIC X(07) VALUE SPACES.

       01  GRANDTOTAL-LINE.
           05 FILLER              PIC X(26) VALUE
              '** GRAND TOTAL            '.
           05 FILLER              PIC X(04) VALUE SPACES.
           05 FILLER              PIC X(13) VALUE ' (BOOKINGS:  '.
           05 GT-COUNT            PIC ZZ,ZZ9.
           05 FILLER              PIC X(14) VALUE ')             '.
           05 GT-ROOM             PIC ZZ,ZZZ,ZZ9.99.
           05 FILLER              PIC X(01) VALUE SPACES.
           05 GT-SVC              PIC ZZ,ZZZ,ZZ9.99.
           05 FILLER              PIC X(01) VALUE SPACES.
           05 GT-TAX              PIC ZZ,ZZZ,ZZ9.99.
           05 FILLER              PIC X(01) VALUE SPACES.
           05 GT-TOT              PIC ZZZ,ZZZ,ZZ9.99.
           05 FILLER              PIC X(06) VALUE SPACES.

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-OPEN-FILES
           PERFORM 2000-PROCESS UNTIL END-OF-FILE
           PERFORM 2800-PRINT-SUBTOTAL
           PERFORM 2900-PRINT-GRANDTOTAL
           PERFORM 3000-CLOSE-FILES
           STOP RUN.

       1000-OPEN-FILES.
           STRING FUNCTION CURRENT-DATE (1:4) '-'
                  FUNCTION CURRENT-DATE (5:2) '-'
                  FUNCTION CURRENT-DATE (7:2)
                  DELIMITED BY SIZE INTO WS-TODAY
           OPEN INPUT  IN-FILE
           OPEN OUTPUT RPT-FILE
           IF WS-FS-IN NOT = '00' OR WS-FS-RPT NOT = '00'
              DISPLAY 'HRBSRPT: OPEN ERROR FS-IN=' WS-FS-IN
                      ' FS-RPT=' WS-FS-RPT
              MOVE 12 TO RETURN-CODE
              STOP RUN
           END-IF
           PERFORM 1100-READ-INVOICE.

       1100-READ-INVOICE.
           READ IN-FILE
              AT END SET END-OF-FILE TO TRUE
           END-READ.

       2000-PROCESS.
      *---- DETERMINE ROOM TYPE (FROM EXTENSION OR INFERRED) ----------*
           IF IR-RTYPE-EXT = 'STD ' OR IR-RTYPE-EXT = 'DLX '
              OR IR-RTYPE-EXT = 'STE '
              MOVE IR-RTYPE-EXT TO WS-CURRENT-RTYPE
           ELSE
              PERFORM 2050-INFER-ROOM-TYPE
           END-IF

      *---- CHECK FOR CONTROL BREAK ON ROOM TYPE ---------------------*
           IF FIRST-RECORD
              MOVE WS-CURRENT-RTYPE TO WS-PREV-RTYPE
              MOVE 'N' TO WS-FIRST-REC
           ELSE
              IF WS-CURRENT-RTYPE NOT = WS-PREV-RTYPE
                 PERFORM 2800-PRINT-SUBTOTAL
                 MOVE WS-CURRENT-RTYPE TO WS-PREV-RTYPE
              END-IF
           END-IF

           PERFORM 2100-PRINT-DETAIL
           PERFORM 2200-ACCUMULATE-TOTALS
           PERFORM 1100-READ-INVOICE.

       2050-INFER-ROOM-TYPE.
           IF IR-NIGHTS > 0
              COMPUTE WS-SUB-TOTALS = IR-ROOM / IR-NIGHTS
              IF SUB-COUNT <= 4000
                 MOVE 'STD ' TO WS-CURRENT-RTYPE
              ELSE
                 IF SUB-COUNT <= 6000
                    MOVE 'DLX ' TO WS-CURRENT-RTYPE
                 ELSE
                    MOVE 'STE ' TO WS-CURRENT-RTYPE
                 END-IF
              END-IF
           ELSE
              MOVE 'STD ' TO WS-CURRENT-RTYPE
           END-IF.

       2100-PRINT-DETAIL.
           IF WS-LINE-COUNT >= WS-MAX-LINES
              PERFORM 2500-PRINT-HEADINGS
           END-IF

           MOVE IR-ID            TO DT-INVID
           MOVE IR-GUEST         TO DT-GUESTID
           MOVE IR-NAME          TO DT-NAME
           MOVE IR-RES           TO DT-RESVID
           MOVE WS-CURRENT-RTYPE TO DT-RTYPE
           MOVE IR-NIGHTS        TO DT-NIGHTS
           MOVE IR-ROOM          TO DT-ROOM
           MOVE IR-SVC           TO DT-SVC
           MOVE IR-TAX           TO DT-TAX
           MOVE IR-TOT           TO DT-TOT
           IF IR-STATUS = 'P'
              MOVE 'PAID  ' TO DT-STATUS
           ELSE
              MOVE 'UNPAID' TO DT-STATUS
           END-IF

           WRITE RPT-REC FROM DETAIL-LINE
           ADD 1 TO WS-LINE-COUNT.

       2200-ACCUMULATE-TOTALS.
           ADD 1      TO SUB-COUNT
           ADD IR-ROOM TO SUB-ROOM
           ADD IR-SVC  TO SUB-SVC
           ADD IR-TAX  TO SUB-TAX
           ADD IR-TOT  TO SUB-TOT

           ADD 1      TO GRD-COUNT
           ADD IR-ROOM TO GRD-ROOM
           ADD IR-SVC  TO GRD-SVC
           ADD IR-TAX  TO GRD-TAX
           ADD IR-TOT  TO GRD-TOT.

       2500-PRINT-HEADINGS.
           ADD 1 TO WS-PAGE-NUM
           MOVE WS-TODAY    TO H1-DATE
           MOVE WS-PAGE-NUM TO H1-PAGE

           IF WS-PAGE-NUM > 1
              MOVE SPACES TO RPT-REC
              WRITE RPT-REC
           END-IF
           WRITE RPT-REC FROM HDG-LINE-1
           WRITE RPT-REC FROM HDG-LINE-2
           WRITE RPT-REC FROM DIVIDER-DOUBLE
           WRITE RPT-REC FROM COL-HEADINGS
           WRITE RPT-REC FROM DIVIDER-SINGLE
           MOVE 6 TO WS-LINE-COUNT.

       2800-PRINT-SUBTOTAL.
           IF SUB-COUNT > 0
              IF WS-LINE-COUNT + 4 >= WS-MAX-LINES
                 PERFORM 2500-PRINT-HEADINGS
              END-IF
              WRITE RPT-REC FROM DIVIDER-SINGLE
              MOVE WS-PREV-RTYPE TO ST-RTYPE
              MOVE SUB-COUNT     TO ST-COUNT
              MOVE SUB-ROOM      TO ST-ROOM
              MOVE SUB-SVC       TO ST-SVC
              MOVE SUB-TAX       TO ST-TAX
              MOVE SUB-TOT       TO ST-TOT
              WRITE RPT-REC FROM SUBTOTAL-LINE
              WRITE RPT-REC FROM DIVIDER-SINGLE
              MOVE SPACES TO RPT-REC
              WRITE RPT-REC
              ADD 4 TO WS-LINE-COUNT

              INITIALIZE WS-SUB-TOTALS
           END-IF.

       2900-PRINT-GRANDTOTAL.
           IF WS-LINE-COUNT + 5 >= WS-MAX-LINES
              PERFORM 2500-PRINT-HEADINGS
           END-IF
           WRITE RPT-REC FROM DIVIDER-DOUBLE
           MOVE GRD-COUNT TO GT-COUNT
           MOVE GRD-ROOM  TO GT-ROOM
           MOVE GRD-SVC   TO GT-SVC
           MOVE GRD-TAX   TO GT-TAX
           MOVE GRD-TOT   TO GT-TOT
           WRITE RPT-REC FROM GRANDTOTAL-LINE
           WRITE RPT-REC FROM DIVIDER-DOUBLE
           MOVE '**** END OF REPORT ****' TO RPT-REC
           WRITE RPT-REC.

       3000-CLOSE-FILES.
           CLOSE IN-FILE RPT-FILE
           DISPLAY '-------------------------------------------'
           DISPLAY 'HRBSRPT - BILLING REPORT SUMMARY'
           DISPLAY 'TOTAL INVOICES PRINTED: ' GRD-COUNT
           DISPLAY 'PAGES GENERATED       : ' WS-PAGE-NUM
           DISPLAY '-------------------------------------------'.
