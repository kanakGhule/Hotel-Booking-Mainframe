/* REXX */
/*********************************************************************/
/* HOTEL RESERVATION AND BILLING SYSTEM (HRBS)                       */
/* TSO COMMAND-LINE UTILITY (INVOKED FROM ISPF 6 OR TSO READY)       */
/*                                                                   */
/* SYNTAX:                                                           */
/*   TSO %HRBSUTIL COUNT  <dsname>                                   */
/*   TSO %HRBSUTIL CHKDUP <dsname> <start_col> <length>              */
/*   TSO %HRBSUTIL FIND   <dsname> <reservation_id>                  */
/*                                                                   */
/* EXAMPLES:                                                         */
/*   %HRBSUTIL COUNT  HRBS.RESERV.INPUT                              */
/*   %HRBSUTIL CHKDUP HRBS.RESERV.INPUT 13 8                         */
/*   %HRBSUTIL FIND   HRBS.RESERV.INPUT RS006881                     */
/*                                                                   */
/* RETURN CODES:                                                     */
/*   0 = SUCCESS                                                     */
/*   4 = WARNING (DUPLICATE FOUND / RECORD NOT FOUND)                */
/*   8 = INVALID SYNTAX / FILE ERROR                                 */
/*********************************************************************/
parse upper arg cmd dsn arg3 arg4 rest

if cmd = '' | cmd = 'HELP' | cmd = '?' then do
   call print_usage
   exit 0
end

if dsn = '' then do
   say 'HRBSUTIL: ERROR - DATASET NAME IS REQUIRED.'
   call print_usage
   exit 8
end

/* Ensure dataset name has quotes if not provided */
if left(dsn, 1) <> "'" then
   full_dsn = "'" || dsn || "'"
else
   full_dsn = dsn

select
   when cmd = 'COUNT'  then call do_count
   when cmd = 'CHKDUP' then call do_chkdup
   when cmd = 'FIND'   then call do_find
   otherwise do
      say 'HRBSUTIL: UNKNOWN COMMAND "'cmd'".'
      call print_usage
      exit 8
   end
end
exit 0

/* ----------------------------------------------------------------- */
/* DO_COUNT: COUNTS RECORDS IN A DATASET                             */
/* ----------------------------------------------------------------- */
do_count:
   call alloc_file
   address TSO "EXECIO * DISKR UTLDD (STEM in. FINIS"
   r_rc = rc
   if r_rc <> 0 & r_rc <> 2 then do
      say 'HRBSUTIL: READ ERROR ON ' full_dsn ', EXECIO RC=' r_rc
      call free_file
      exit 8
   end
   call free_file
   say '=================================================='
   say 'HRBSUTIL: DATASET RECORD COUNT SUMMARY'
   say 'DATASET  : ' full_dsn
   say 'RECORDS  : ' in.0
   say '=================================================='
   return

/* ----------------------------------------------------------------- */
/* DO_CHKDUP: CHECKS FOR DUPLICATES ON KEY RANGE                     */
/* ----------------------------------------------------------------- */
do_chkdup:
   if arg3 = '' | arg4 = '' then do
      say 'HRBSUTIL: ERROR - CHKDUP REQUIRES START_COL AND LENGTH.'
      say 'SYNTAX: %HRBSUTIL CHKDUP <dsn> <start_col> <length>'
      exit 8
   end
   k_start = arg3
   k_len   = arg4
   if \datatype(k_start, 'W') | \datatype(k_len, 'W') then do
      say 'HRBSUTIL: START_COL AND LENGTH MUST BE POSITIVE INTEGERS.'
      exit 8
   end

   call alloc_file
   address TSO "EXECIO * DISKR UTLDD (STEM in. FINIS"
   r_rc = rc
   if r_rc <> 0 & r_rc <> 2 then do
      say 'HRBSUTIL: READ ERROR ON ' full_dsn ', EXECIO RC=' r_rc
      call free_file
      exit 8
   end
   call free_file

   seen. = 0
   dup_cnt = 0
   say '=================================================='
   say 'HRBSUTIL: KEY DUPLICATE AUDIT REPORT'
   say 'DATASET  : ' full_dsn
   say 'KEY RANGE: COL ' k_start ' FOR ' k_len ' BYTES'
   say 'RECORDS  : ' in.0
   say '--------------------------------------------------'

   do i = 1 to in.0
      k = 'K' || substr(in.i, k_start, k_len)
      if seen.k > 0 then do
         dup_cnt = dup_cnt + 1
         say 'DUPLICATE #' dup_cnt ': KEY="'substr(in.i, k_start, k_len)'"' ,
             'AT RECORD' i ' (FIRST SEEN AT REC 'seen.k')'
      end
      else
         seen.k = i
   end

   say '--------------------------------------------------'
   if dup_cnt = 0 then do
      say 'RESULT: VERIFIED - ZERO DUPLICATES FOUND.'
      say '=================================================='
      return
   end
   else do
      say 'RESULT: AUDIT FAILED - ' dup_cnt ' DUPLICATES DETECTED.'
      say '=================================================='
      exit 4
   end

/* ----------------------------------------------------------------- */
/* DO_FIND: FINDS AND FORMATS A RESERVATION BY ID                    */
/* ----------------------------------------------------------------- */
do_find:
   if arg3 = '' then do
      say 'HRBSUTIL: ERROR - RESERVATION ID REQUIRED.'
      say 'SYNTAX: %HRBSUTIL FIND <dsn> <resid>'
      exit 8
   end
   find_id = arg3

   call alloc_file
   address TSO "EXECIO * DISKR UTLDD (STEM in. FINIS"
   r_rc = rc
   if r_rc <> 0 & r_rc <> 2 then do
      say 'HRBSUTIL: READ ERROR ON ' full_dsn ', EXECIO RC=' r_rc
      call free_file
      exit 8
   end
   call free_file

   found = 0
   do i = 1 to in.0
      /* Key is at cols 13-20 */
      if length(in.i) >= 20 then
         cur_id = substr(in.i, 13, 8)
      else
         cur_id = ''

      if cur_id = find_id then do
         found = 1
         r = in.i
         say '=================================================='
         say 'HRBSUTIL: RESERVATION RECORD LOCATED (REC #' i ')'
         say '=================================================='
         say 'RECORD TYPE : ' substr(r, 1, 3)
         say 'HOTEL CODE  : ' substr(r, 4, 3)
         say 'BOOKING DATE: 20' || substr(r, 7, 2) || '-' || ,
                              substr(r, 9, 2) || '-' || substr(r, 11, 2)
         say 'RESV ID     : ' substr(r, 13, 8)
         say 'GUEST NAME  : ' strip(substr(r, 21, 20))
         say 'ROOM NO     : ' substr(r, 41, 4)
         say 'ROOM TYPE   : ' substr(r, 45, 4)
         say 'CHECK-IN    : ' substr(r, 49, 4) || '-' || ,
                              substr(r, 53, 2) || '-' || substr(r, 55, 2)
         say 'CHECK-OUT   : ' substr(r, 57, 4) || '-' || ,
                              substr(r, 61, 2) || '-' || substr(r, 63, 2)
         say 'GUESTS      : ' substr(r, 65, 2)
         say 'NIGHTLY RATE: INR ' || (substr(r, 67, 6) + 0)
         say 'STATUS      : ' substr(r, 73, 1)
         say '=================================================='
         leave
      end
   end

   if found = 0 then do
      say 'HRBSUTIL: RESERVATION "'find_id'" NOT FOUND IN ' full_dsn
      exit 4
   end
   return

/* ----------------------------------------------------------------- */
/* ALLOC_FILE / FREE_FILE: TSO DYNAMIC ALLOCATION HELPERS            */
/* ----------------------------------------------------------------- */
alloc_file:
   address TSO "ALLOC FI(UTLDD) DA("full_dsn") SHR REUSE"
   if rc <> 0 then do
      say 'HRBSUTIL: ALLOCATION FAILED FOR ' full_dsn ', RC=' rc
      exit 8
   end
   return

free_file:
   address TSO "FREE FI(UTLDD)"
   return

/* ----------------------------------------------------------------- */
/* PRINT_USAGE: DISPLAYS COMMAND SYNTAX                              */
/* ----------------------------------------------------------------- */
print_usage:
   say '=================================================='
   say 'HRBSUTIL - HRBS TSO BATCH AND ISPF UTILITY'
   say '=================================================='
   say 'USAGE:'
   say '  %HRBSUTIL COUNT  <dsname>'
   say '  %HRBSUTIL CHKDUP <dsname> <start_col> <length>'
   say '  %HRBSUTIL FIND   <dsname> <reservation_id>'
   say ''
   say 'EXAMPLES:'
   say '  TSO %HRBSUTIL COUNT  HRBS.RESERV.INPUT'
   say '  TSO %HRBSUTIL CHKDUP HRBS.RESERV.INPUT 13 8'
   say '  TSO %HRBSUTIL FIND   HRBS.RESERV.INPUT RS006881'
   say '=================================================='
   return
