#!/usr/bin/env python3
"""
Hotel Reservation and Billing System (HRBS) - Reference Implementation Runner
Independently computes expected outputs for every job and assignment,
storing verified baseline outputs under data/expected/.
"""

import os
import sys
import shutil
import sqlite3
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
EXP_DIR = os.path.join(DATA_DIR, "expected")

os.makedirs(EXP_DIR, exist_ok=True)

def run_all_references():
    print("=" * 70)
    print("HRBS REFERENCE IMPLEMENTATION & EXPECTED DATA GENERATOR")
    print("=" * 70)

    # 1. Assignment 1: DFSORT Dedupe & Sort
    print("[1/7] Computing Assignment 1 (RESERV.dat -> 90 unique sorted)...")
    with open(os.path.join(DATA_DIR, "RESERV.dat"), "r", encoding="utf-8") as f:
        resv_raw = [l.rstrip("\r\n") for l in f if l.strip()]
    seen_keys = set()
    a1_dedup = []
    for r in resv_raw:
        k = r[12:20]
        if k not in seen_keys:
            seen_keys.add(k)
            a1_dedup.append(r)
    a1_sorted = sorted(a1_dedup, key=lambda x: x[12:20])
    with open(os.path.join(EXP_DIR, "EXPECTED_A1.dat"), "w", newline="\n", encoding="utf-8") as f:
        f.write("\n".join(a1_sorted) + "\n")
    print(f"      -> {len(a1_sorted)} records written to EXPECTED_A1.dat")

    # 2. Assignment 2: Two-File Match
    print("[2/7] Computing Assignment 2 (FILE1.dat + FILE2.dat -> 35 matches)...")
    with open(os.path.join(DATA_DIR, "FILE1.dat"), "r", encoding="utf-8") as f:
        f1 = [l.rstrip("\r\n") for l in f if l.strip()]
    with open(os.path.join(DATA_DIR, "FILE2.dat"), "r", encoding="utf-8") as f:
        f2 = [l.rstrip("\r\n") for l in f if l.strip()]
    p_map = {p[20:28]: p for p in f2}
    matched = []
    for r in f1:
        rid = r[12:20]
        if rid in p_map:
            matched.append(r + p_map[rid])
    with open(os.path.join(EXP_DIR, "EXPECTED_A2_MATCH.dat"), "w", newline="\n", encoding="utf-8") as f:
        f.write("\n".join(matched) + "\n")
    print(f"      -> {len(matched)} records (160 B) written to EXPECTED_A2_MATCH.dat")

    # 3. Assignment 3: REXX Dedupe & Shell Sort
    print("[3/7] Computing Assignment 3 (INVOICE.dat -> 105 unique sorted)...")
    with open(os.path.join(DATA_DIR, "INVOICE.dat"), "r", encoding="utf-8") as f:
        inv_raw = [l.rstrip("\r\n") for l in f if l.strip()]
    seen_inv = set()
    a3_dedup = []
    for i in inv_raw:
        k = i[24:32]
        if k not in seen_inv:
            seen_inv.add(k)
            a3_dedup.append(i)
    a3_sorted = sorted(a3_dedup, key=lambda x: x[24:32])
    with open(os.path.join(EXP_DIR, "EXPECTED_A3.dat"), "w", newline="\n", encoding="utf-8") as f:
        f.write("\n".join(a3_sorted) + "\n")
    print(f"      -> {len(a3_sorted)} records written to EXPECTED_A3.dat")

    # 4. HRBSVAL Validation Rejects
    print("[4/7] Computing HRBSVAL Validation Rejects on RESERV_BAD.dat...")
    with open(os.path.join(DATA_DIR, "RESERV_BAD.dat"), "r", encoding="utf-8") as f:
        bad_recs = [l.rstrip("\r\n") for l in f if l.strip()]
    reject_lines = []
    for r in bad_recs:
        # Evaluate reason
        rtype = r[0:3]
        rid = r[12:20]
        cin = r[48:56]
        cout = r[56:64]
        rm_type = r[44:48]
        guests = int(r[64:66]) if r[64:66].isdigit() else 0
        rate = int(r[66:72]) if r[66:72].isdigit() else 0
        status = r[72:73]

        code = "00"
        msg = "UNKNOWN ERROR                         "
        if rtype != "RSV":
            code, msg = "01", "INVALID RECORD TYPE (EXPECTED RSV)    "
        elif not (rid.startswith("RS") and rid[2:].isdigit()):
            code, msg = "02", "INVALID RES-ID FORMAT (RS+6 DIGITS)  "
        elif int(r[6:8]) > 12 or int(r[6:8]) < 1:
            code, msg = "03", "INVALID BOOKING DATE (YYMMDD)        "
        elif int(cin[4:6]) > 12 or int(cin[4:6]) < 1 or (cin[4:6] == "02" and int(cin[6:8]) > 29):
            code, msg = "04", "INVALID CHECK-IN DATE (YYYYMMDD)     "
        elif int(cout[4:6]) > 12 or int(cout[4:6]) < 1 or (cout[4:6] in ["04","06","09","11"] and int(cout[6:8]) > 30):
            code, msg = "05", "INVALID CHECK-OUT DATE (YYYYMMDD)    "
        elif cout <= cin:
            code, msg = "06", "CHECK-OUT DATE NOT AFTER CHECK-IN    "
        elif rm_type not in ["STD ", "DLX ", "STE "]:
            code, msg = "07", "INVALID ROOM TYPE (NOT STD/DLX/STE)  "
        elif guests < 1 or guests > 4:
            code, msg = "08", "GUEST COUNT OUT OF RANGE (1 - 4)     "
        elif (rm_type == "STD " and rate != 3500) or (rm_type == "DLX " and rate != 5200) or (rm_type == "STE " and rate != 8800):
            code, msg = "09", "RATE INCONSISTENT WITH ROOM TYPE     "
        elif status not in ["C", "X", "O"]:
            code, msg = "10", "INVALID STATUS (NOT C, X, OR O)      "

        rej_line = f"{r[:80]:<80}{code:<2}{msg:<38}"
        assert len(rej_line) == 120, len(rej_line)
        reject_lines.append(rej_line)

    with open(os.path.join(EXP_DIR, "EXPECTED_VAL_REJECT.dat"), "w", newline="\n", encoding="utf-8") as f:
        f.write("\n".join(reject_lines) + "\n")
    print(f"      -> {len(reject_lines)} reject records (120 B) written to EXPECTED_VAL_REJECT.dat")

    # 5. HRBSBIL Invoices
    print("[5/7] Computing HRBSBIL Billing Invoices (90 reservations)...")
    invoices = []
    seq = 0
    today = datetime.now().strftime("%Y%m%d")
    total_billed = 0.0
    for r in a1_sorted:
        hotel = r[3:6]
        rid = r[12:20]
        name = r[20:40]
        cin = datetime.strptime(r[48:56], "%Y%m%d")
        cout = datetime.strptime(r[56:64], "%Y%m%d")
        rate = int(r[66:72])
        nights = max(1, (cout - cin).days)
        room = nights * rate
        svc = round(room * 0.05, 2)
        tax_rate = 0.18 if rate > 7500 else 0.05
        tax = round((room + svc) * tax_rate, 2)
        tot = round(room + svc + tax, 2)
        seq += 1
        total_billed += tot

        inv_rec = (
            "INV" + hotel + today +
            f"G{seq:09d}" +
            f"IN{seq:06d}" +
            rid + name +
            f"{nights:03d}" +
            f"{int(round(room * 100)):08d}" +
            f"{int(round(svc * 100)):08d}" +
            f"{int(round(tax * 100)):08d}" +
            f"{int(round(tot * 100)):010d}" +
            "P" + "  "
        )
        assert len(inv_rec) == 100, len(inv_rec)
        invoices.append(inv_rec)

    with open(os.path.join(EXP_DIR, "EXPECTED_INVOICE_BILLED.dat"), "w", newline="\n", encoding="utf-8") as f:
        f.write("\n".join(invoices) + "\n")
    print(f"      -> {len(invoices)} invoices (100 B) written. Total: INR {total_billed:,.2f}")

    # 6. Report Summary
    print("[6/7] Computing Billing Report Totals by Room Type...")
    # Derive from reservations and invoices
    room_types = {}
    for inv, r in zip(invoices, a1_sorted):
        rtype = r[44:48].strip()
        nights = int(inv[60:63])
        room = int(inv[63:71]) / 100.0
        svc = int(inv[71:79]) / 100.0
        tax = int(inv[79:87]) / 100.0
        tot = int(inv[87:97]) / 100.0
        if rtype not in room_types:
            room_types[rtype] = {"count": 0, "room": 0.0, "svc": 0.0, "tax": 0.0, "tot": 0.0}
        room_types[rtype]["count"] += 1
        room_types[rtype]["room"] += room
        room_types[rtype]["svc"] += svc
        room_types[rtype]["tax"] += tax
        room_types[rtype]["tot"] += tot

    rep_lines = ["HRBS BILLING REPORT - REFERENCE TOTALS BY ROOM TYPE:"]
    for rt in sorted(room_types.keys()):
        d = room_types[rt]
        rep_lines.append(f"Room Type: {rt:<4} | Bookings: {d['count']:<3} | Room: INR {d['room']:>12,.2f} | Svc: INR {d['svc']:>10,.2f} | Tax: INR {d['tax']:>10,.2f} | Total: INR {d['tot']:>12,.2f}")
    rep_lines.append(f"GRAND TOTAL     | Bookings: {len(invoices):<3} | Total Revenue: INR {total_billed:>14,.2f}")

    with open(os.path.join(EXP_DIR, "EXPECTED_REPORT_SUMMARY.txt"), "w", newline="\n", encoding="utf-8") as f:
        f.write("\n".join(rep_lines) + "\n")
    print(f"      -> Report totals written to EXPECTED_REPORT_SUMMARY.txt")

    # 7. DB2 Row Counts & Unpaid Query
    print("[7/7] Computing DB2 Expected Counts and Unpaid Bills...")
    con = sqlite3.connect(":memory:")
    cur = con.cursor()
    schema_raw = open(os.path.join(BASE_DIR, "db2", "SCHEMA.sql"), encoding="utf-8").read()
    clean_lines = []
    for line in schema_raw.splitlines():
        if line.strip().startswith("CREATE DATABASE") or line.strip().startswith("CREATE TABLESPACE"):
            continue
        line = line.replace("IN HRBSDB.HRBSTS", "")
        line = line.replace("WITH DEFAULT", "DEFAULT")
        line = line.replace("HRBS.", "")
        clean_lines.append(line)
    cur.executescript("\n".join(clean_lines))

    # Insert all 90 reservations and invoices
    for inv, r in zip(invoices, a1_sorted):
        rid = r[12:20]
        gid = "G000000001"
        rm = r[40:44]
        cin = f"{r[48:52]}-{r[52:54]}-{r[54:56]}"
        cout = f"{r[56:60]}-{r[60:62]}-{r[62:64]}"
        gst = int(r[64:66])
        stat = r[72:73]
        cur.execute("INSERT OR IGNORE INTO RESERVATION VALUES (?, ?, ?, ?, ?, ?, ?)",
                    (rid, gid, rm, cin, cout, gst, stat))

        invid = inv[24:32]
        bdate = f"{inv[6:10]}-{inv[10:12]}-{inv[12:14]}"
        nts = int(inv[60:63])
        rmc = int(inv[63:71]) / 100.0
        svc = int(inv[71:79]) / 100.0
        tax = int(inv[79:87]) / 100.0
        tot = int(inv[87:97]) / 100.0
        cur.execute("INSERT OR IGNORE INTO BILL VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'P')",
                    (invid, rid, bdate, nts, rmc, svc, tax, tot))

    con.commit()
    db2_summary = [
        "DB2 EXPECTED METRICS:",
        f"GUEST Table Rows       : {cur.execute('SELECT COUNT(*) FROM GUEST').fetchone()[0]}",
        f"ROOM Table Rows        : {cur.execute('SELECT COUNT(*) FROM ROOM').fetchone()[0]}",
        f"RESERVATION Table Rows : {cur.execute('SELECT COUNT(*) FROM RESERVATION').fetchone()[0]}",
        f"BILL Table Rows        : {cur.execute('SELECT COUNT(*) FROM BILL').fetchone()[0]}",
        f"PAYMENT Table Rows     : {cur.execute('SELECT COUNT(*) FROM PAYMENT').fetchone()[0]}",
    ]
    with open(os.path.join(EXP_DIR, "EXPECTED_DB2_COUNTS.txt"), "w", newline="\n", encoding="utf-8") as f:
        f.write("\n".join(db2_summary) + "\n")
    print(f"      -> DB2 baseline counts written to EXPECTED_DB2_COUNTS.txt")

    print("=" * 70)
    print("ALL REFERENCE OUTPUTS SUCCESSFULLY COMPUTED UNDER data/expected/")
    print("=" * 70)

if __name__ == "__main__":
    run_all_references()
