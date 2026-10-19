      ******************************************************************
      * DCLGEN TABLE(HRBS.GUEST)                                      *
      ******************************************************************
           EXEC SQL DECLARE HRBS.GUEST TABLE
           ( GUEST_ID                       CHAR(10) NOT NULL,
             GUEST_NAME                     VARCHAR(30) NOT NULL,
             PHONE                          CHAR(10),
             CITY                           VARCHAR(20)
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE HRBS.GUEST                         *
      ******************************************************************
       01  DCL-GUEST.
           10 HV-GUEST-ID                   PIC X(10).
           10 HV-GUEST-NAME.
              49 HV-GUEST-NAME-LEN          PIC S9(4) USAGE COMP.
              49 HV-GUEST-NAME-TEXT         PIC X(30).
           10 HV-GUEST-PHONE                PIC X(10).
           10 HV-GUEST-CITY.
              49 HV-GUEST-CITY-LEN          PIC S9(4) USAGE COMP.
              49 HV-GUEST-CITY-TEXT         PIC X(20).
      ******************************************************************
      * INDICATOR VARIABLES FOR HRBS.GUEST                             *
      ******************************************************************
       01  IND-GUEST.
           10 IND-GUEST-PHONE               PIC S9(4) COMP.
           10 IND-GUEST-CITY                PIC S9(4) COMP.
