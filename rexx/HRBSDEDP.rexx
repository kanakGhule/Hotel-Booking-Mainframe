/* REXX */
/*********************************************************************/
/* HOTEL RESERVATION AND BILLING SYSTEM (HRBS) - ASSIGNMENT 3         */
/* READ INVOICE FILE (DD INDD, 100-BYTE RECORDS), REMOVE DUPLICATES,  */
/* SORT ON PRIMARY KEY (COLS 25-32) ASCENDING, WRITE TO DD OUTDD.     */
/* RUN IN BATCH (IKJEFT01) OR IN TSO AFTER ALLOCATING INDD / OUTDD.   */
/*********************************************************************/
keyStart = 25
keyLen   = 8

address TSO
"EXECIO * DISKR INDD (STEM in. FINIS"
read_rc = rc
if read_rc <> 0 & read_rc <> 2 then do
   say 'HRBSDEDP: READ ERROR, EXECIO RC='read_rc
   exit 8
end
total = in.0
say 'HRBSDEDP: RECORDS READ            =' total

/* ---- STEP A: REMOVE DUPLICATES (FIRST OCCURRENCE OF A KEY WINS) --- */
seen. = 0
n = 0
do i = 1 to total
   k = 'K' || substr(in.i, keyStart, keyLen)
   if seen.k = 0 then do
      seen.k = 1
      n = n + 1
      rec.n = in.i
      key.n = substr(in.i, keyStart, keyLen)
   end
end
dups = total - n
say 'HRBSDEDP: DUPLICATES REMOVED      =' dups
say 'HRBSDEDP: UNIQUE RECORDS          =' n

/* ---- STEP B: SORT ON KEY (SHELL SORT, STRICT STRING COMPARE) ------ */
gap = n % 2
do while gap > 0
   do i = gap + 1 to n
      tmpRec = rec.i
      tmpKey = key.i
      j = i
      do while j > gap
         p = j - gap
         if key.p >> tmpKey then do
            rec.j = rec.p
            key.j = key.p
            j = p
         end
         else leave
      end
      rec.j = tmpRec
      key.j = tmpKey
   end
   gap = gap % 2
end

/* ---- STEP C: WRITE RESULT ---------------------------------------- */
rec.0 = n
"EXECIO" n "DISKW OUTDD (STEM rec. FINIS"
if rc <> 0 then do
   say 'HRBSDEDP: WRITE ERROR, EXECIO RC='rc
   exit 12
end
say 'HRBSDEDP: RECORDS WRITTEN         =' n
say 'HRBSDEDP: COMPLETED SUCCESSFULLY'
exit 0
