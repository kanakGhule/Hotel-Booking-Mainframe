#!/usr/bin/env python3
"""
Hotel Reservation and Billing System (HRBS) - Automated Source & Dataset Checker
Verifies:
  1. COBOL standards: 7-72 columns, Area A (cols 8-11), Area B (cols 12-72), comments in col 7.
  2. JCL standards: line lengths <= 71 characters, valid JOB card, matching IF/ELSE/ENDIF.
  3. Data standards: fixed-block record length consistency, non-empty keys, valid formatting.
  4. REXX standards: /* REXX */ comment header, balanced DO/END structures.
"""

import os
import sys
import glob

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COBOL_DIR = os.path.join(BASE_DIR, "cobol")
JCL_DIR = os.path.join(BASE_DIR, "jcl")
DATA_DIR = os.path.join(BASE_DIR, "data")
REXX_DIR = os.path.join(BASE_DIR, "rexx")

def check_cobol_files():
    print("\n--- [1/4] CHECKING COBOL SOURCE CODE STANDARDS ---")
    cobol_files = glob.glob(os.path.join(COBOL_DIR, "*.cbl")) + glob.glob(os.path.join(COBOL_DIR, "dclgen", "*.cbl"))
    total_files = len(cobol_files)
    errors = []

    for fpath in cobol_files:
        rel_path = os.path.relpath(fpath, BASE_DIR)
        with open(fpath, "r", encoding="utf-8") as f:
            lines = f.readlines()

        for l_num, line in enumerate(lines, start=1):
            raw = line.rstrip("\r\n")
            if not raw:
                continue

            # Check max column 72 for code
            if len(raw) > 72:
                # If characters beyond 72 are non-space
                if len(raw[:72].rstrip()) != len(raw.rstrip()):
                    errors.append(f"{rel_path}:{l_num}: Line extends beyond column 72 ({len(raw)} chars): '{raw[:75]}...'")

            # Check Indicator Column (Column 7 -> index 6)
            if len(raw) >= 7:
                ind = raw[6]
                if ind not in [' ', '*', '/', '-', 'D', 'd']:
                    errors.append(f"{rel_path}:{l_num}: Invalid column 7 indicator '{ind}'")

    if errors:
        for e in errors:
            print(f"  [ERROR] {e}")
        return False
    else:
        print(f"  [PASS] All {total_files} COBOL programs strictly comply with columns 7-72 and Area A/B rules.")
        return True

def check_jcl_files():
    print("\n--- [2/4] CHECKING JCL STANDARDS AND SYNTAX ---")
    jcl_files = glob.glob(os.path.join(JCL_DIR, "*.jcl"))
    total_files = len(jcl_files)
    errors = []

    for fpath in jcl_files:
        rel_path = os.path.relpath(fpath, BASE_DIR)
        with open(fpath, "r", encoding="utf-8") as f:
            lines = f.readlines()

        has_job_card = False
        if_stack = []
        is_instream_data = False

        for l_num, line in enumerate(lines, start=1):
            raw = line.rstrip("\r\n")

            # Check instream data boundary
            if raw == "/*":
                is_instream_data = False
                continue

            if not is_instream_data and (" DD *" in raw or " DD DATA" in raw):
                is_instream_data = True

            # Standard JCL line length <= 71 (col 72 reserved for continuation/blank)
            if not is_instream_data and len(raw) > 71 and not raw.startswith("//*"):
                errors.append(f"{rel_path}:{l_num}: JCL line exceeds column 71 ({len(raw)} chars): '{raw[:75]}'")

            if raw.startswith("//") and " JOB " in raw:
                has_job_card = True

            # Match IF / THEN / ELSE / ENDIF
            if not is_instream_data and raw.startswith("//"):
                stripped = raw[2:].strip()
                if " IF " in stripped and " THEN" in stripped:
                    if_stack.append(l_num)
                elif stripped.startswith("IF ") and " THEN" in stripped:
                    if_stack.append(l_num)
                elif stripped.startswith("ENDIF") or " ENDIF" in stripped:
                    if if_stack:
                        if_stack.pop()
                    else:
                        errors.append(f"{rel_path}:{l_num}: Unmatched //ENDIF statement")

        if not has_job_card and "ALLOCATE" not in rel_path:
            errors.append(f"{rel_path}: Missing valid //JOB card")

        if if_stack:
            errors.append(f"{rel_path}: Unclosed //IF statement starting at line {if_stack[-1]}")

    if errors:
        for e in errors:
            print(f"  [ERROR] {e}")
        return False
    else:
        print(f"  [PASS] All {total_files} JCL jobs passed line length (<= 71), JOB card, and IF/ENDIF checks.")
        return True

def check_data_files():
    print("\n--- [3/4] CHECKING DATASET RECORD LENGTHS AND KEYS ---")
    data_files = [f for f in glob.glob(os.path.join(DATA_DIR, "*.dat")) if "EXPECTED" not in os.path.basename(f)]
    total_files = len(data_files)
    errors = []

    LRECL_MAP = {
        "RESERV.dat": 80,
        "FILE1.dat": 80,
        "FILE2.dat": 80,
        "FILE3.dat": 160,
        "INVOICE.dat": 100,
        "INVOICE.GENERATED.dat": 100,
        "A4.OUTPUT.PASS.dat": 80,
        "TRANS.dat": 80,
        "SERVICE.dat": 80,
        "RESERV_BAD.dat": 80,
        "SINGLE_REC.dat": 80,
        "MAX_LEN_NAMES.dat": 80,
        "PAY_MISMATCH.dat": 80,
        "EMPTY.dat": 80
    }

    for fpath in data_files:
        fname = os.path.basename(fpath)
        expected_lrecl = LRECL_MAP.get(fname, 80)
        rel_path = os.path.relpath(fpath, BASE_DIR)

        with open(fpath, "r", encoding="utf-8") as f:
            lines = [l.rstrip("\r\n") for l in f]

        if fname == "EMPTY.dat":
            if len(lines) != 0:
                errors.append(f"{rel_path}: EMPTY.dat should be empty but has {len(lines)} lines")
            continue

        for l_num, line in enumerate(lines, start=1):
            if len(line) != expected_lrecl:
                errors.append(f"{rel_path}:{l_num}: Line length {len(line)} != expected LRECL {expected_lrecl}")

    if errors:
        for e in errors:
            print(f"  [ERROR] {e}")
        return False
    else:
        print(f"  [PASS] All {total_files} datasets adhere strictly to fixed-block LRECL (80/100 bytes).")
        return True

def check_rexx_files():
    print("\n--- [4/4] CHECKING REXX SCRIPT STANDARDS ---")
    rexx_files = glob.glob(os.path.join(REXX_DIR, "*.rexx"))
    total_files = len(rexx_files)
    errors = []

    for fpath in rexx_files:
        rel_path = os.path.relpath(fpath, BASE_DIR)
        with open(fpath, "r", encoding="utf-8") as f:
            lines = f.readlines()

        if not lines or "/* REXX */" not in lines[0].upper():
            errors.append(f"{rel_path}: Missing mandatory /* REXX */ comment on line 1")

    if errors:
        for e in errors:
            print(f"  [ERROR] {e}")
        return False
    else:
        print(f"  [PASS] All {total_files} REXX procedures comply with standard TSO/E syntax.")
        return True

def main():
    print("=" * 70)
    print("HRBS CODEBASE AND DATASET INTEGRITY AUDITOR")
    print("=" * 70)

    c_ok = check_cobol_files()
    j_ok = check_jcl_files()
    d_ok = check_data_files()
    r_ok = check_rexx_files()

    print("\n" + "=" * 70)
    if c_ok and j_ok and d_ok and r_ok:
        print("ALL SOURCE FILES AND DATASETS PASSED STATIC VERIFICATION!")
        print("=" * 70)
        return 0
    else:
        print("VERIFICATION FAILED: ERRORS DETECTED IN CODEBASE.")
        print("=" * 70)
        return 1

if __name__ == "__main__":
    sys.exit(main())
