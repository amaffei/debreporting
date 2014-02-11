# Converts WHOI FSR ITD records to proper "ledger convert" compatible CSV file
# Andrew Maffei - January 9, 2014

### BEFORE WE DO ANYTHING
BEGIN {
  #Define fields separator
  FPAT = "([^, ]+)|(\"[^\"]+\")"
  }
### CLEANUP INDIVIDUAL MISTAKES FOUND IN CERTAIN DOWNLOADS
# STOCKROOM USES DOUBLE-QUOTES FOR INCHES IN DESCRIPTION
#/110517ASTONSCISSOR,2RING,7",GR/ {
#  s/2RING,7"/2RING,7i/
#  print 
#  }
### LINE 1 - Report Description
#"Inception To Date Actuals Detail 84782200 ROLLING DECK REPOSITORY R2R  0 For the period ending January 4, 2014"
/^"Inception To Date Actuals Detail/ {
  match($0,/[0-9][0-9]* /)
  FsrAccountNumber=substr($0,RSTART,8)
  FsrMainAccount=substr(FsrAccountNumber,1,6)
  FsrSubAccount=substr(FsrAccountNumber,7,2)
  next
  }
### LINE 2 - Column Headers
#"Obj./Obj. Desc/TRX Description","Date","Ref.","Ref2.","PEID","Type","Job#","Amount"
# ledger fieldnames are date,desc|description|payee|title,posted,note,amount,code,cost,total
# however we use the original fieldnames unless they are too long
/TRX Description/{ 
    # Prepend ObjCode column to make proper CSV
    #  print "code,description,date,ref,ref2,peid,type,jobno,amount" (equiv ledger fieldnames)
    print "ExpCode,TRXDesc,Date,Ref,Ref2,PEID,Type,JobNo,Amount"
  next
}
### EXPENSE CODE BLOCK SEPARATORS
#"5010 - Salaries - Regular",,,,,,,
#set ExpCode for next block and gather info for aux file output in future
/^"5[0-9][0-9][0-9].*",,,,,,,/ {
  FsrExpCode=substr($0,2,4)
  FsrExpCodeName=substr($1,9)
  #print "FsrExpenseCode, FsrExpenseCodeName =" FsrExpCode "," FsrExpCodeName
  next
  }
### EXPCODE TOTALS
#"","","","","","","Total",195.52
# grab ExpCodeTotal for use in future validation of expcode account total
/^"","","","","","","Total",/ { FsrExpCodeTotal=$8; next}
### FSRACCOUNT TOTAL
#"","","","","","","Account Total",66389.85
# grab FsrAccountTotal for use in future validation of ledger account
/^"","","","","","","Account Total",/ {FsrAccoutTotal=$8; next}
### TRANSACTION ROWS
#"FRINGE BENEFITS-REGULAR","2012-03-02","01005DP","","N/A..N/A","ST","1519535",6.24
// {
  # Get rid of <cr> at end of line
  sub(/.$/,//)
  # FIELD1 - FSR DESCRIPTION (remove whitespace and quotes)
  FsrDesc=$1
  gsub (/[ 	][ 	]*/," ",FsrDesc)
  gsub(/\"/,"",FsrDesc)
  # FIELD2 - FSR DATE (leave as-is for now, reformat later)
  FsrDate=$2
  # FIELD3 - FSR REF (remove quotes)
  FsrRef=$3
  gsub(/\"/,"",FsrRef)
  # FIELD4 - FSR REF2 (remove quotes)
  FsrRef2=$4
  gsub(/\"/,"",FsrRef2)
  # FIELD5 - FSR PEID (leave as-is)
  FsrPEID=$5
  # FIELD6 - FSR TYPE (leave as-is)
  FsrType=$6
  # FIELD7 - FSR JOB# (leave as is)
  FsrJobNum=$7
  # FIELD8 - FSR AMOUNT (set $minus, remove last bogus character)
  FsrAmount=$8
  if(match(FsrAmount,/^-/)) {minus=1} else {minus=0}
  gsub(/.$/,"",FsrAmount)
  #
  # PRINT ROW TO STDOUT
  # hold onto negated amount in case we want to use that instead of FsrAmount in some
  # scripts
  NegateAmount=FsrAmount
  if(minus) {gsub(/-/,"",NegateAmount)} else {gsub(/^/,"-",NegateAmount)}
  print FsrExpCode ", \"" FsrDesc "\","  substr(FsrDate,2,4) "/" substr(FsrDate,7,2) "/" substr(FsrDate,10,2) ",\"" FsrRef "\",\"" FsrRef2 "\"," FsrPEID "," FsrType "," FsrJobNum "," FsrAmount
  # END OF TRANSACTION ROW
  }
