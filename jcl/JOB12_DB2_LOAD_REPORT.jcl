//HRBSJ12  JOB (ACCT),'HRBS DB2 LOAD',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//*--------------------------------------------------------------------
//* DB2 PRECOMPILE, COMPILE, LINK-EDIT, BIND AND RUN HRBSDB2
//* ALL SITE-SPECIFIC PARAMETERS CONFIGURED IN THE SET BLOCK BELOW:
//*--------------------------------------------------------------------
//         SET HLQ='&SYSUID..HRBS'
//         SET DB2SSID='DB2P'
//         SET DB2PLAN='HRBSPLAN'
//         SET DB2COLL='HRBSCOLL'
//         SET DB2LOAD='DSN120.SDSNLOAD'
//         SET DB2RUN='DSN120.RUNLIB.LOAD'
//         SET DB2PROC='DSNHPC'
//*--------------------------------------------------------------------
//* STEP 1: PRECOMPILE, COMPILE AND LINK-EDIT VIA DB2 PROC
//*--------------------------------------------------------------------
//DB2COMP  EXEC &DB2PROC,MEM=HRBSDB2
//PC.SYSIN     DD DISP=SHR,DSN=&HLQ..COBOL(HRBSDB2)
//PC.SYSLIB    DD DISP=SHR,DSN=&HLQ..COBOL.DCLGEN
//LKED.SYSLMOD DD DISP=SHR,DSN=&HLQ..LOAD(HRBSDB2)
//*--------------------------------------------------------------------
//* STEP 2: BIND DB2 PACKAGE AND APPLICATION PLAN
//*--------------------------------------------------------------------
//BIND     EXEC PGM=IKJEFT01,DYNAMNBR=20,COND=(4,LT,DB2COMP)
//STEPLIB  DD DISP=SHR,DSN=&DB2LOAD
//DBRMLIB  DD DISP=SHR,DSN=&HLQ..DBRM
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *,SYMBOLS=JCLSUB
  DSN SYSTEM(&DB2SSID)
  BIND PACKAGE(&DB2COLL) MEMBER(HRBSDB2) -
       ACTION(REPLACE) ISOLATION(CS) VALIDATE(BIND)
  BIND PLAN(&DB2PLAN) PKLIST(&DB2COLL.*) -
       ACTION(REPLACE) RETAIN
  END
/*
//*--------------------------------------------------------------------
//* STEP 3: EXECUTE BATCH DB2 PROGRAM HRBSDB2
//*--------------------------------------------------------------------
//RUN      EXEC PGM=IKJEFT01,DYNAMNBR=20,COND=(4,LT,BIND)
//STEPLIB  DD DISP=SHR,DSN=&DB2LOAD
//         DD DISP=SHR,DSN=&HLQ..LOAD
//RESVIN   DD DISP=SHR,DSN=&HLQ..RESERV.VALID
//INVIN    DD DISP=SHR,DSN=&HLQ..INVOICE.OUTPUT
//SYSTSPRT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CEEDUMP  DD SYSOUT=*
//SYSTSIN  DD *,SYMBOLS=JCLSUB
  DSN SYSTEM(&DB2SSID)
  RUN PROGRAM(HRBSDB2) PLAN(&DB2PLAN) LIB('&HLQ..LOAD')
  END
/*
