      ******************************************************************
      * DCLGEN TABLE(HRBS.PAYMENT)                                    *
      ******************************************************************
           EXEC SQL DECLARE HRBS.PAYMENT TABLE
           ( PAYMENT_ID                     CHAR(8) NOT NULL,
             RES_ID                         CHAR(8) NOT NULL,
             PAY_DATE                       DATE NOT NULL,
             PAY_MODE                       CHAR(3) NOT NULL,
             AMOUNT                         DECIMAL(12,2) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE HRBS.PAYMENT                       *
      ******************************************************************
       01  DCL-PAYMENT.
           10 HV-PAYMENT-ID                 PIC X(08).
           10 HV-PAY-RES-ID                 PIC X(08).
           10 HV-PAY-DATE                   PIC X(10).
           10 HV-PAY-MODE                   PIC X(03).
           10 HV-PAY-AMOUNT                 PIC S9(10)V99 USAGE COMP-3.
