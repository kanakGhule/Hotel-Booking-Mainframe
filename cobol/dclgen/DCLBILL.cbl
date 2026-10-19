      ******************************************************************
      * DCLGEN TABLE(HRBS.BILL)                                       *
      ******************************************************************
           EXEC SQL DECLARE HRBS.BILL TABLE
           ( INVOICE_ID                     CHAR(8) NOT NULL,
             RES_ID                         CHAR(8) NOT NULL,
             BILL_DATE                      DATE NOT NULL,
             NIGHTS                         SMALLINT NOT NULL,
             ROOM_CHARGE                    DECIMAL(10,2) NOT NULL,
             SERVICE_CHARGE                 DECIMAL(10,2) NOT NULL,
             TAX                            DECIMAL(10,2) NOT NULL,
             TOTAL                          DECIMAL(12,2) NOT NULL,
             PAY_STATUS                     CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE HRBS.BILL                          *
      ******************************************************************
       01  DCL-BILL.
           10 HV-INVOICE-ID                 PIC X(08).
           10 HV-BILL-RES-ID                PIC X(08).
           10 HV-BILL-DATE                  PIC X(10).
           10 HV-NIGHTS                     PIC S9(4) USAGE COMP.
           10 HV-ROOM-CHARGE                PIC S9(8)V99 USAGE COMP-3.
           10 HV-SERVICE-CHARGE             PIC S9(8)V99 USAGE COMP-3.
           10 HV-TAX                        PIC S9(8)V99 USAGE COMP-3.
           10 HV-TOTAL                      PIC S9(10)V99 USAGE COMP-3.
           10 HV-PAY-STATUS                 PIC X(01).
