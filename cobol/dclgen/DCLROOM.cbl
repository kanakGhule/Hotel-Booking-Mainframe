      ******************************************************************
      * DCLGEN TABLE(HRBS.ROOM)                                       *
      ******************************************************************
           EXEC SQL DECLARE HRBS.ROOM TABLE
           ( ROOM_NO                        CHAR(4) NOT NULL,
             ROOM_TYPE                      CHAR(3) NOT NULL,
             RATE_PER_NIGHT                 DECIMAL(8,2) NOT NULL,
             STATUS                         CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE HRBS.ROOM                          *
      ******************************************************************
       01  DCL-ROOM.
           10 HV-ROOM-NO                    PIC X(04).
           10 HV-ROOM-TYPE                  PIC X(03).
           10 HV-RATE-PER-NIGHT             PIC S9(6)V99 USAGE COMP-3.
           10 HV-ROOM-STATUS                PIC X(01).
