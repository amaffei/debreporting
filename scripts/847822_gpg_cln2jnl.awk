# Converts WHOI FSR ITD records to ledger transactions
# Andrew Maffei - December 31, 2013
# TODO:
#Usage: /usr/bin/awk -f fsr2ledger.awk

### BEFORE WE DO ANYTHING
BEGIN {
  #Define fields separator
  FPAT = "([^, ]+)|(\"[^\"]+\")"
#  print "\; -*- ledger -*-"
  }
### CLEANUP INDIVIDUAL MISTAKES IN WHOI FSRS
# STOCKROOM USES DOUBLE-QUOTES FOR INCHES IN DESCRIPTION
#/110517ASTONSCISSOR,2RING,7",GR/ {
#  $1="\" DESCRIPTION IS MESSED UP\""
#  $2=$3
#  $3=$4
#  $4=$5
#  $5=$6
#  $6=$7
#  next
#  }
### LINE 1 - Desciprtion of the FSR Report !!NEEDS TO BE MORE SPECIFIC!!
/^"Inception To Date Budget Detail/ {
  match($0,/[0-9][0-9]* /)
  FsrAccountNumber=substr($0,RSTART,8)
  FsrMainAccount=substr(FsrAccountNumber,1,6)
  FsrSubAccount=substr(FsrAccountNumber,7,2)
  # print "bucket Assets:" FsrMainAccount ":" FsrSubAccount
  next
  }
### LINE 2 - Column Headers - !!Need to make this more explicit later!!
#/^"Obj./Obj. Desc/Dtl. Description","Year","Date","User No.","Ref.","Amount"/ {next}
/Dtl. Description/ {next}
### EXPENSE CODE SECTION SEPARATORS ROWS
/^"5[0-9][0-9][0-9] - .*",,,,,/ {
  FsrExpenseCode=substr($0,2,4)
  next
  }
### SUBTOTALS AND TOTALS ROWS
/^"","","","","Total",/ {
  FsrExpCodeTotal=$6
  # Check subtotal against running total
  #print substr(FsrDate,2,4) "/" substr(FsrDate,7,2) "/" substr(FsrDate,10,2) "  Subtotal Check for " FsrMainAccount ":" FsrSubAccount ":" FsrExpenseCode
  #print "  WHOIView:Expenses:" FsrMainAccount ":" FsrSubAccount ":" FsrExpenseCode ":		$0  = $" FsrExpCodeTotal
  #print "  WHOIView:Assets:" FsrMainAccount ":" FsrSubAccount
  #print ""
  #NOTE -- NEXT LINE IS A KLUDGE. The last row with the word "total" in it is an account
  #        Total but there is no other distinguishing factors. Need to set this variable
  #        in another way. It is only valid after all rows have been processed
  FsrMainAccountTotal=$5
  next
  }
### ALL OTHER LINES ARE REAL
// {
  # Get rid of <cr> at end of line
  sub(/.$/,//)
  # Gather all the info from the row that you can
  # FSR Description Field (remove quotes and extra spaces)
  FsrDesc=$1
  gsub (/[ 	][ 	]*/," ",FsrDesc)
  gsub(/\"/," ",FsrDesc)
  if(match(FsrDesc,/Entry From/)) {} else {FsrDesc="Entry from ????"}
  # FSR Budget Year
  FsrBudYear=$2
  # FSR Transaction Date Field (reformat for QIF-like data)
  FsrDate=$3
  # FSR User Number
  FsrUserNo=$4
  # FSR Ref Field (remove quotes)
  FsrRef=$5
  # FSR Amount (remove last bogus character)
  FsrAmount=$6
  if(match(FsrAmount,/^-/)) {minus=1} else {minus=0}
  gsub(/.$/,"",FsrAmount)
  #
  # Time to Print out the Transaction
  #
  print substr(FsrDate,2,4) "/" substr(FsrDate,7,2) "/" substr(FsrDate,10,2) " " FsrExpenseCode " " FsrDesc
  Amount=FsrAmount
  if(minus) {gsub(/-/,"",Amount)} else {gsub(/^/,"-",Amount)}
  #print "  " FsrMainAccount FsrSubAccount ":WHOIView:Budget:" FsrExpenseCode "		$" FsrAmount "  ; " FsrMemo
  # #print "  " FsrMainAccount FsrSubAccount ":WHOIView:NSF Grant"

  print "  WHOIView:Assets:" FsrExpenseCode "		$" FsrAmount "  ; " FsrMemo
  print "  WHOIView:Income:Grant"
  print ""
  # ENDOFRECORD
  }
