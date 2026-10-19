      ******************************************************************
      * DCLGEN TABLE(HRBS.RESERVATION)                                *
      ******************************************************************
           EXEC SQL DECLARE HRBS.RESERVATION TABLE
           ( RES_ID                         CHAR(8) NOT NULL,
             GUEST_ID                       CHAR(10) NOT NULL,
             ROOM_NO                        CHAR(4) NOT NULL,
             CHECK_IN                       DATE NOT NULL,
             CHECK_OUT                      DATE NOT NULL,
             NO_OF_GUESTS                   SMALLINT NOT NULL,
             STATUS                         CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE HRBS.RESERVATION                   *
      ******************************************************************
       01  DCL-RESERVATION.
           10 HV-RES-ID                     PIC X(08).
           10 HV-RESV-GUEST-ID              PIC X(10).
           10 HV-RESV-ROOM-NO               PIC X(04).
           10 HV-CHECK-IN                   PIC X(10).
           10 HV-CHECK-OUT                  PIC X(10).
           10 HV-NO-OF-GUESTS               PIC S9(4) USAGE COMP.
           10 HV-RESV-STATUS                PIC X(01).
