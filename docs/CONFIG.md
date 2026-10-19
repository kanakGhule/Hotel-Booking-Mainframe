# HRBS - Site Configuration & Customization Guide

This document lists every site-specific parameter and environment setting that students must verify or modify before executing the **Hotel Reservation and Billing System (HRBS)** on their college or organization z/OS mainframe.

---

## 1. Quick Reference: Values to Change

| Parameter | Default in Repo | Typical College / Lab Value | Where to Change |
|---|---|---|---|
| **User ID / HLQ** | `&SYSUID` | Your TSO ID (e.g. `KC03002`, `STU045`) | JCL JOB cards, dataset names |
| **COBOL Proc** | `IGYWCL` | `IGYWCL`, `IGYWC`, `COBCL` | `jcl/JOB02`, `06`, `07`, `09`, `11`, `10` |
| **DB2 Subsystem ID** | `DB2P` | `DSN`, `DB2T`, `DB2A`, `D101` | `jcl/JOB05`, `jcl/JOB12`, `jcl/JOB10` |
| **DB2 Plan Name** | `HRBSPLAN` | `HRBSPLAN` or assigned plan | `jcl/JOB12` (`SET DB2PLAN=...`) |
| **DB2 Collection** | `HRBSCOLL` | `HRBSCOLL` or `<userid>_COLL` | `jcl/JOB12` (`SET DB2COLL=...`) |
| **DB2 SDSNLOAD DSN** | `DSN120.SDSNLOAD` | `DSN110.SDSNLOAD`, `DSN130.SDSNLOAD` | `jcl/JOB05`, `jcl/JOB12` |
| **DB2 RUNLIB DSN** | `DSN120.RUNLIB.LOAD` | `DSN110.RUNLIB.LOAD` | `jcl/JOB05`, `jcl/JOB12` |
| **DB2 Precompile Proc** | `DSNHPC` | `DSNHPC`, `DSNHCOB2` | `jcl/JOB12` (`SET DB2PROC=...`) |
| **DSNTEP2 Plan** | `DSNTEP2` | `DSNTEP12`, `DSNTEP2` | `jcl/JOB05` |
| **SMS Storage Unit** | Default (SMS managed) | `SYSDA`, `3390` | If site requires explicit `UNIT=SYSDA` |

---

## 2. JCL SET Block Parameterization (Centralized in JOB12)

In [jcl/JOB12_DB2_LOAD_REPORT.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB12_DB2_LOAD_REPORT.jcl), all site-specific variables are consolidated in a single `SET` block at the beginning of the job stream:

```jcl
//         SET HLQ='&SYSUID..HRBS'
//         SET DB2SSID='DB2P'
//         SET DB2PLAN='HRBSPLAN'
//         SET DB2COLL='HRBSCOLL'
//         SET DB2LOAD='DSN120.SDSNLOAD'
//         SET DB2RUN='DSN120.RUNLIB.LOAD'
//         SET DB2PROC='DSNHPC'
```

If your institution uses a different DB2 subsystem or library name, update only these lines.

---

## 3. Dataset Naming Convention

By default, every JCL job uses `&SYSUID` as the High-Level Qualifier (HLQ). When you submit a job under your TSO ID, the system automatically resolves `&SYSUID` to your login name.

For example, if your login is `KC03002`:
- `&SYSUID..HRBS.RESERV.INPUT` $\rightarrow$ `KC03002.HRBS.RESERV.INPUT`
- `&SYSUID..HRBS.COBOL` $\rightarrow$ `KC03002.HRBS.COBOL`
- `&SYSUID..HRBS.RESERV.KSDS` $\rightarrow$ `KC03002.HRBS.RESERV.KSDS`

> [!NOTE]
> If your lab administrator assigns a shared project prefix (such as `CE.VIT.HRBS`), replace `&SYSUID..HRBS` with your assigned prefix across all JCL files.

---

## 4. COBOL Compiler Options

The provided source code conforms to standard IBM Enterprise COBOL for z/OS (v4.2, v5.x, v6.x). If your site requires explicit compiler options, add the following to `COBOL.SYSIN` or the compile step `PARM`:

```jcl
//COMPILE EXEC IGYWCL,PARM.COBOL='LIB,APOST,NODYNAM,SSRANGE'
```

---

## 5. Business Constants & Policy Tuning

In [cobol/HRBSBIL.cbl](file:///e:/mainframe%20project%20sem%201/hrbs/cobol/HRBSBIL.cbl), all hospitality pricing and taxation parameters are defined in `WORKING-STORAGE`:

```cobol
       01  WS-BILLING-PARAMETERS.
           05 PARM-BASE-SVC-RATE  PIC 9V99 VALUE 0.05.   *> 5% Base Service Charge
           05 PARM-GST-SLAB-LIMIT PIC 9(06) VALUE 7500.   *> GST Tariff Threshold (INR)
           05 PARM-GST-LOW-RATE   PIC 9V99 VALUE 0.05.   *> 5% GST for <= 7500 INR
           05 PARM-GST-HIGH-RATE  PIC 9V99 VALUE 0.18.   *> 18% GST for > 7500 INR
```

To modify tax slabs for current fiscal year guidelines before your presentation demo, adjust these constants and recompile with [jcl/JOB06_COBOL_BILL.jcl](file:///e:/mainframe%20project%20sem%201/hrbs/jcl/JOB06_COBOL_BILL.jcl).
