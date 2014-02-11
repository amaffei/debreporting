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
/^"Encumbrance To Date Transaction Detail/ {
  match($0,/[0-9][0-9]* /)
  FsrAccountNumber=substr($0,RSTART,8)
  FsrMainAccount=substr(FsrAccountNumber,1,6)
  FsrSubAccount=substr(FsrAccountNumber,7,2)
  # print "bucket Assets:" FsrMainAccount ":" FsrSubAccount
  next
  }
###
### LINE 2 - Column Headers - !!Need to make this more explicit later!!
#"Obj./Obj. Desc/TRX Description","Ref.","Ref. Date","Post Date","PEID","PE Name","Amount"
/TRX Description/ {next}
###
### EXPENSE CODE SECTION SEPARATORS
#"5210 - Supplies",,,,,,
/^"5[0-9][0-9][0-9] - .*",,,,,,/ {
  FsrExpenseCode=substr($0,2,4)
  match($0,/ - [^"][^"]*/)
  FsrExpenseName=substr($0,4)
  next
  }
###
### SUBTOTALS AND TOTALS
/^"","","","","","Total",/ {
  FsrExpCodeTotal=$7
  # Check subtotal against running total
  #print substr(FsrDate,2,4) "/" substr(FsrDate,7,2) "/" substr(FsrDate,10,2) "  Subtotal Check for " FsrMainAccount ":" FsrSubAccount ":" FsrExpenseCode
  #print "  WHOIView:Expenses:" FsrMainAccount ":" FsrSubAccount ":" FsrExpenseCode ":		$0  = $" FsrExpCodeTotal
  #print "  WHOIView:Assets:" FsrMainAccount ":" FsrSubAccount
  #print ""
  next
  }
/^"","","","","","Account Total",/ {FsrMainAccoutTotal=$7; next}
###
### ALL OTHER LINES ARE REAL
// {
  # Get rid of <cr> at end of line
  sub(/.$/,//)
  # Gather all the info from the row that you can
  # FSR Description Field (remove quotes and extra spaces)
  FsrDesc=$1
  gsub (/[ 	][ 	]*/," ",FsrDesc)
  gsub(/\"/,"",FsrDesc)
  # FSR Transaction Date Field (reformat for QIF-like data)
  FsrDate=$3
  # FSR Ref Field (remove quotes)
  FsrRef=$2
  gsub(/\"/,"",FsrRef)
  FsrPostDate=$4
  gsub(/\"/,"",FsrPostDate)
  FsrPEID=$5
  # FSR Type (not sure what this is)
  FsrPEName=$6
  # FSR Amount (remove last bogus character)
  FsrAmount=$7
  if(match(FsrAmount,/^-/)) {minus=1} else {minus=0}
  gsub(/.$/,"",FsrAmount)
  # 
  # ASSIGN CATEGORIES TO FSR RECORDS (WILL GET TRANSLATED TO GNUCASH ACCOUNTS)
  #
  # Assign Default FSR Categories first, by looking at FsrExpenseCode
  AndyViewCr="Encumberances:Unassigned"
  GBMFViewCr="Unassigned"
  if(FsrExpenseCode == 5210) {AndyViewCr="Encumberances:Supplies";GBMFViewCr="Encumberances:Materials and Supplies:Supplies"
    AndyViewCr="Encumberances:Supplies:Unassigned";GBMFViewCr="Encumberances:Other Direct Costs:Materials and Supplies:Supplies:Unassigned"
    if (match($FsrDesc,"TIMOTHY E THIEL")) {AndyViewCr="Encumberances:TimothyT Contract";GBMFViewCr="Encumberances:TimothyT Contract"}
}
   if(FsrExpenseCode == 5310) {AndyViewCr="Encumberances:OtherOutServ"
    AndyViewCr="Encumberances:OtherOutServ:Unassigned";GBMFViewCr="Encumberances:Other Direct Costs:OtherOutServ:Unassigned";
    if (match($FsrDesc,"TIMOTHY E THIEL")) {AndyViewCr="Encumberances:TimothyT Contract";GBMFViewCr="Encumberances:TimothyT Contract"}
   }
  #
  # Print WHOIView Transaction
  # print "debug FsrDesc,FsrRef,FsrDate,FsrPostDate,FsrPEID,FsrPEName,FsrAmount=" FsrDesc "," FsrRef "," FsrDate "," FsrPostDate "," FsrPEID "," FsrPEName "," FsrAmount
  print substr(FsrDate,2,4) "/" substr(FsrDate,7,2) "/" substr(FsrDate,10,2) " " FsrExpenseCode " " FsrDesc
  Amount=FsrAmount
  if(minus) {gsub(/-/,"",Amount)} else {gsub(/^/,"-",Amount)}
  #print "  " FsrMainAccount FsrSubAccount ":WHOIView:Expenses:" FsrExpenseCode "		$" FsrAmount "  ; " FsrMemo
  #print  "  " FsrMainAccount FsrSubAccount ":WHOIView:Budget"
  print "  WHOIView:Liabilities:" FsrExpenseCode "		$" FsrAmount "  ; " FsrMemo
  print "  WHOIView:Assets:" FsrExpenseCode
  #
  # Print AndyView Virtual Account Info
  #print "  (" FsrMainAccount FsrSubAccount ":AndyView:" AndyViewCr ") 		$" FsrAmount
  print "  (AndyView:" AndyViewCr ") 		$" FsrAmount 
  #
  # Print GBMFView Virtual Account Info
  #print "  (" FsrMainAccount FsrSubAccount ":GBMFView:" GBMFViewCr ") 		$" FsrAmount 
  print "  (GBMFView:" GBMFViewCr ") 		$" FsrAmount 
  #print ""
  # ENDOFRECORD
  }
