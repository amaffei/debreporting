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
/^"Inception To Date Actuals Detail/ {
  match($0,/[0-9][0-9]* /)
  FsrAccountNumber=substr($0,RSTART,8)
  FsrMainAccount=substr(FsrAccountNumber,1,6)
  FsrSubAccount=substr(FsrAccountNumber,7,2)
  # print "bucket Assets:" FsrMainAccount ":" FsrSubAccount
  next
  }
### LINE 2 - Column Headers - !!Need to make this more explicit later!!
#/^"Obj./Obj. Desc/TRX Description","Date","Ref.","Ref2.","PEID","Type","Job#","Amount"/ {next}
/TRX Description/ {next}
### EXPENSE CODE SECTION SEPARATORS
/^"5[0-9][0-9][0-9].*",,,,,,,/ {
  FsrExpenseCode=substr($0,2,4)
  next
  }
### SUBTOTALS AND TOTALS
/^"","","","","","","Total",/ {
  FsrExpCodeTotal=$8
  # Check subtotal against running total
  #print substr(FsrDate,2,4) "/" substr(FsrDate,7,2) "/" substr(FsrDate,10,2) "  Subtotal Check for " FsrMainAccount ":" FsrSubAccount ":" FsrExpenseCode
  #print "  WHOIView:Expenses:" FsrMainAccount ":" FsrSubAccount ":" FsrExpenseCode ":		$0  = $" FsrExpCodeTotal
  #print "  WHOIView:Assets:" FsrMainAccount ":" FsrSubAccount
  #print ""
  next
  }
/^"","","","","","","Account Total",/ {FsrMainAccoutTotal=$8; next}
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
  FsrDate=$2
  # FSR Ref Field (remove quotes)
  FsrRef=$3
  gsub(/\"/,"",FsrRef)
  FsrRef2=$4
  gsub(/\"/,"",FsrRef2)
  FsrPEID=$5
  # FSR Type (not sure what this is)
  FsrType=$6
  # FSR Job Number (not sure what this is)
  FsrJobNum=$7
  # FSR Amount (remove last bogus character)
  FsrAmount=$8
  if(match(FsrAmount,/^-/)) {minus=1} else {minus=0}
  gsub(/.$/,"",FsrAmount)
  # 
  # ASSIGN CATEGORIES TO FSR RECORDS (WILL GET TRANSLATED TO GNUCASH ACCOUNTS)
  #
  # Assign Default FSR Categories first, by looking at FsrExpenseCode
  AndyViewCr="Expenses:Unassigned"
  GBMFViewCr="Unassigned"
  if(FsrExpenseCode == 5010) {AndyViewCr="Expenses:Salary:Regular";GBMFViewCr="Labor and Benefits"}
  if(FsrExpenseCode == 5012) {AndyViewCr="Expenses:Salary:PaidAbsence";GBMFViewCr="Labor and Benefits"}
  if(FsrExpenseCode == 5015) {AndyViewCr="Expenses:Salary:Casual";GBMFViewCr="Labor and Benefits"}
  if(FsrExpenseCode == 5050) {AndyViewCr="Expenses:Salary:BenifitsRegular";GBMFViewCr="Labor and Benefits"}
  if(FsrExpenseCode == 5054) {AndyViewCr="Expenses:Salary:BenifitsCasual";GBMFViewCr="Labor and Benefits"}
  if(FsrExpenseCode == 5060) {AndyViewCr="Expenses:Salary:LabCostsRegular";GBMFViewCr="Indirect Costs:Lab Costs"}
  if(FsrExpenseCode == 5066) {AndyViewCr="Expenses:Salary:LabCostsCasual";GBMFViewCr="Indirect Costs:Lab Costs"}
  if(FsrExpenseCode == 5100) {AndyViewCr="Expenses:Other:ElecMechCarp";GBMFViewCr="Other Direct Costs:Other:Shop"}
  if(FsrExpenseCode == 5130) {AndyViewCr="Expenses:Other:Graphics";GBMFViewCr="Other Direct Costs:Other:Shop"}
  if(FsrExpenseCode == 5170) {AndyViewCr="Expenses:Travel"
    AndyViewCr="Expenses:Travel:Unassigned";GBMFViewCr="Travel:Domestic:Unassigned";
    if (match($FsrDesc,"AMAFF")) {AndyViewCr="Expenses:Travel:AndyM:Domestic";GBMFViewCr="Travel:Domestic:AndyM"}
    if (match($FsrDesc,"MAFFEI")) {AndyViewCr="Expenses:Travel:AndyM:Domestic";GBMFViewCr="Travel:Domestic:AndyM"}
    if (match($FsrDesc,"SHEPHERD")) {AndyViewCr="Expenses:Travel:AdamS:Domestic";GBMFViewCr="Travel:Domestic:AdamS"}
    if (match($FsrDesc,"CCHAN")) {AndyViewCr="Expenses:Travel:CyndyC:Domestic";GBMFViewCr="Travel:Domestic:CyndyC"}
    if (match($FsrDesc,"STOLP")) {AndyViewCr="Expenses:Travel:LauraS:Domestic";GBMFViewCr="Travel:Domestic:LauraS"}
    if (match($FsrDesc,"RARKO")) {AndyViewCr="Expenses:Travel:BobA:Domestic";GBMFViewCr="Travel:Domestic:BobA"}
    if (match($FsrDesc,"JFUTR")) {AndyViewCr="Expenses:Travel:JoeF:Domestic";GBMFViewCr="Travel:Domestic:JoeF"}
    if (match($FsrDesc,"FUTRELLE")) {AndyViewCr="Expenses:Travel:JoeF:Domestic";GBMFViewCr="Travel:Domestic:JoeF"}
    if (match($FsrDesc,"SOSIK, HEIDI")) {AndyViewCr="Expenses:Travel:HeidiS:Domestic";GBMFViewCr="Travel:Domestic:HeidiS"}
    if (match($FsrDesc,"HSOSI/PT")) {AndyViewCr="Expenses:Travel:HeidiS:Domestic";GBMFViewCr="Travel:Domestic:HeidiS"}
    if (match($FsrDesc,"JPMC HSOSI")) {AndyViewCr="Expenses:Travel:HeidiS:Domestic";GBMFViewCr="Travel:Domestic:HeidiS"}
    if (match($FsrDesc,"HONIG, PETER")) {AndyViewCr="Expenses:Travel:PeterH:Domestic";GBMFViewCr="Travel:Domestic:PeterH"}
    if (match($FsrDesc,"FOX, PETER")) {AndyViewCr="Expenses:Travel:PeterF:Domestic";GBMFViewCr="Travel:Domestic:PeterF"}
    if (match($FsrDesc,"WEST, PATRICK")) {AndyViewCr="Expenses:Travel:PatrickW:Domestic";GBMFViewCr="Travel:Domestic:PatrickW"}
    if (match($FsrDesc,"SINGH, HANUMAN")) {AndyViewCr="Expenses:Travel:HanuS:Domestic";GBMFViewCr="Travel:Domestic:HanuS"}
    if (match($FsrDesc,"HSING")) {AndyViewCr="Expenses:Travel:HanuS:Domestic";GBMFViewCr="Travel:Domestic:HanuS"}
    if (match($FsrDesc,"YORK, AMBER")) {AndyViewCr="Expenses:Travel:AmberY:Domestic";GBMFViewCr="Travel:Domestic:AmberY"}
    if (match($FsrDesc,"PRASAD, LAKSHM")) {AndyViewCr="Expenses:Travel:LakshmanP:Domestic";GBMFViewCr="Travel:Domestic:LakshmanP"}
    if (match($FsrDesc,"LPRAS")) {AndyViewCr="Expenses:Travel:LakshmanP:Domestic";GBMFViewCr="Travel:Domestic:LakshmanP"}
    if (match($FsrDesc,"SLEEPY HOLLOW")) {AndyViewCr="Expenses:Travel:Sleepy Hollow:Domestic";GBMFViewCr="Travel:Domestic:Sleepy Hollow"}
    if (match($FsrDesc,"COBURN, ELIZABE")) {AndyViewCr="Expenses:Travel:LizaC:Domestic";GBMFViewCr="Travel:Domestic:LizaC"}
    if (match($FsrDesc,"CNOBR")) {AndyViewCr="Expenses:Travel:CarolinaN:Domestic";GBMFViewCr="Travel:Domestic:CarolinaN"}
    if (match($FsrDesc,"CSELL")) {AndyViewCr="Expenses:Travel:CindyS:Domestic";GBMFViewCr="Travel:Domestic:CindyS"}
    if (match($FsrDesc,"CHANDLER, CYNTH")) {AndyViewCr="Expenses:Travel:CyndyC:Domestic";GBMFViewCr="Travel:Domestic:CyndyC"}
    if (match($FsrDesc,"NOBRE, CAROLINA")) {AndyViewCr="Expenses:Travel:CarolinaN:Domestic";GBMFViewCr="Travel:Domestic:CarolinaN"}
    } 
  if(FsrExpenseCode == 5171) {AndyViewCr="Expenses:Travel:SeminarFee";GBMFViewCr="Travel:SeminarFee";
    AndyViewCr="Expenses:Travel:SeminarFee:Unassigned";GBMFViewCr="Travel:SeminarFee:Unassigned";
    if (match($FsrDesc,"JFUTR")) {AndyViewCr="Expenses:Travel:JoeF:SeminarFee";GBMFViewCr="Travel:SeminarFee:JoeF"}
    if (match($FsrDesc,"AMAFF")) {AndyViewCr="Expenses:Travel:AndyM:SeminarFee";GBMFViewCr="Travel:SeminarFee:AndyM"}
    if (match($FsrDesc,"CSELL")) {AndyViewCr="Expenses:Travel:CindyS:SeminarFee";GBMFViewCr="Travel:SeminarFee:CindyS"}
    if (match($FsrDesc,"ASTON")) {AndyViewCr="Expenses:Travel:AnnS:SeminarFee";GBMFViewCr="Travel:SeminarFee:AnnS"}

    }
  if(FsrExpenseCode == 5180) {AndyViewCr="Expenses:Travel"
    AndyViewCr="Expenses:Travel:Unassigned";GBMFViewCr="Travel:International:Unassigned";
    if (match($FsrDesc,"AMAFF")) {AndyViewCr="Expenses:Travel:AndyM:International";GBMFViewCr="Travel:International:AndyM"}
    if (match($FsrDesc,"MAFFEI")) {AndyViewCr="Expenses:Travel:AndyM:International";GBMFViewCr="Travel:International:AndyM"}
    if (match($FsrDesc,"JFUTR")) {AndyViewCr="Expenses:Travel:JoeF:International";GBMFViewCr="Travel:International:JoeF"}
    if (match($FsrDesc,"FUTRELLE")) {AndyViewCr="Expenses:Travel:JoeF:International";GBMFViewCr="Travel:International:JoeF"}
    if (match($FsrDesc,"HSOSI")) {AndyViewCr="Expenses:Travel:HeidiS:International";GBMFViewCr="Travel:International:HeidiS"}
    }
  if(FsrExpenseCode == 5190) {AndyViewCr="Expenses:Equipment";GBMFViewCr="Equipment"
    AndyViewCr="Expenses:Equipment:Unassigned";GBMFViewCr="Equipment:Unassigned"
    if (match($FsrDesc,"APPLE")) {AndyViewCr="Expenses:Equipment:JoesLaptop";GBMFViewCr="Equipment:JoesLaptop"}
    if (match($FsrDesc,"DELL")) {AndyViewCr="Expenses:Equipment:DELLComputers";GBMFViewCr="Equipment:DELLComputers"}
    if (match($FsrDesc,"AMAZON")) {AndyViewCr="Expenses:Equipment:Amazon-Equip";GBMFViewCr="Equipment:Amazon-Equip"}
    }
  if(FsrExpenseCode == 5200) {AndyViewCr="Expenses:Other:Membership Fees";GBMFViewCr="Other Direct Costs:Other:Membership Fees"}
  if(FsrExpenseCode == 5210) {AndyViewCr="Expenses:Supplies";GBMFViewCr="Other Direct Costs:Materials and Supplies:Supplies"}
  if(FsrExpenseCode == 5211) {AndyViewCr="Expenses:Other:ComputerSoftware";GBMFViewCr="Other Direct Costs:Materials and Supplies:ComputerSoftware"}
  if(FsrExpenseCode == 5212) {AndyViewCr="Expenses:Other:ComputerSupplies";GBMFViewCr="Other Direct Costs:Materials and Supplies:ComputerSupplies"}
  if(FsrExpenseCode == 5220) {AndyViewCr="Expenses:Other:Books";GBMFViewCr="Other Direct Costs:Materials and Supplies:Books"}
  if(FsrExpenseCode == 5250) {AndyViewCr="Expenses:Other:Stockroom";GBMFViewCr="Other Direct Costs:Materials and Supplies:Stockroom"
    AndyViewCr="Expenses:Other:Stockroom:Unassigned";GBMFViewCr="Other Direct Costs:Materials and Supplies:Unassigned"
    if (match($FsrDesc,"HONIG, PETER")) {AndyViewCr="Expenses:Other:Strockroom:PeterH";GBMFViewCr="Other Direct Costs:Materials and Supplies:Stockroom:PeterH"}
    if (match($FsrDesc,"STONE, ANN")) {AndyViewCr="Expenses:Other:Strockroom:AnnS";GBMFViewCr="Other Direct Costs:Materials and Supplies:Stockroom:AnnS"}
    if (match($FsrDesc,"KUNZ, CLAYTON")) {AndyViewCr="Expenses:Other:Strockroom:ClaytonK";GBMFViewCr="Other Direct Costs:Materials and Supplies:Stockroom:ClaytonK"}
    if (match($FsrDesc,"KIMBALL, PETER")) {AndyViewCr="Expenses:Other:Strockroom:PeterK";GBMFViewCr="Other Direct Costs:Materials and Supplies:Stockroom:PeterK"}
    if (match($FsrDesc,"SELLERS, CYNTHI NOTEBOOK")) {AndyViewCr="Expenses:Other:Strockroom:CindyS:Notebook";GBMFViewCr="Other Direct Costs:Materials and Supplies:Stockroom:CindyS:Notebook"}
    }
  if(FsrExpenseCode == 5290) {AndyViewCr="Expenses:Other:Meals";GBMFViewCr="Other Direct Costs:Other:Meals"}
  if(FsrExpenseCode == 5310) {AndyViewCr="Expenses:Salary:OtherOutServ"
    AndyViewCr="Expenses:Salary:OtherOutServ:Unassigned";GBMFViewCr="Other Direct Costs:OtherOutServ:Unassigned";
    if (match($FsrDesc,"NYE, MARK")) {AndyViewCr="Expenses:Salary:ConsultingServices:Nye";GBMFViewCr="Other Direct Costs:ConsultingServices:Nye"}
    if (match($FsrDesc,"MARINE BIOLOGI")) {AndyViewCr="Expenses:Salary:OtherOutServ:MBL";GBMFViewCr="Other Direct Costs:ConsultingServiecs:MBL"}
    if (match($FsrDesc,"WEBEX")) {AndyViewCr="Expenses:Other:Communications:Webex:OuterOutsideServ";GBMFViewCr="Other Direct Costs:Other:Webex"}
    if (match($FsrDesc,"TIMOTHY E THIEL")) {AndyViewCr="Expenses:ConsultingServices:TimothyT";GBMFViewCr="Other Direct Costs:TimothyT"}
    }
 if(FsrExpenseCode == 5320) {AndyViewCr="Expenses:ConsultingServices";GBMFViewCr="Other Direct Costs:ConsultingServices"
    AndyViewCr="Expenses:ConsultingServices:Unassigned";GBMFViewCr="Other Direct Costs:ConsultingServices:Unassigned";
    if (match($FsrDesc,"ACQUIA INC PROFESSIONAL")) {AndyViewCr="Expenses:ConsultingServices:Acquia";GBMFViewCr="ConsultingServices:Acquia"}
    }
  if(FsrExpenseCode == 5360) {AndyViewCr="Expenses:Other:Communications"
    AndyViewCr="Expenses:Other:Communications:Unassigned";GBMFViewCr="Other Direct Costs:Other:Communications:Unassigned"
    if (match($FsrDesc,"WEBEX")) {AndyViewCr="Expenses:Other:Communications:Webex";GBMFViewCr="Other Direct Costs:Other:Webex"} 
    if (match($FsrDesc,"VOIP CHG Week ending")) {AndyViewCr="Expenses:Other:Communications:Webex";GBMFViewCr="Other Direct Costs:Other:VOIP"}
    }
  if(FsrExpenseCode == 5370) {AndyViewCr="Expenses:Other:Shipping";GBMFViewCr="Other Direct Costs:Other:Shipping"}
  if(FsrExpenseCode == 5389) {AndyViewCr="Expenses:Other:MiscInHseServ";GBMFViewCr="Other Direct Costs:Other:MiscInHseServ"}
  if(FsrExpenseCode == 5390) {AndyViewCr="Expenses:Other:PrintBind";GBMFViewCr="Other Direct Costs:Other:PrintBind"}
  if(FsrExpenseCode == 5410) {AndyViewCr="Expenses:Other:Miscellaneous";GBMFViewCr="Other Direct Costs:Other:Miscellaneous"}
  if(FsrExpenseCode == 5430) {AndyViewCr="Expenses:Other:Duplicating";GBMFViewCr="Other Direct Costs:Other:Duplicating"}
  if(FsrExpenseCode == 5510) {AndyViewCr="Expenses:Salary:TA";GBMFViewCr="Other Direct Costs:Computer Svc";
    AndyViewCr="Expenses:Salary:TA:Unassigned";GBMFViewCr="Other Direct Costs:Computer Svc:Unassigned";
    if (match($FSRPEID,"05550")) {AndyViewCr="Expenses:Salary:TA:AndyM";GBMFViewCr="Other Direct Costs:Computer Svc:AndyM"}
    if (match($FsrDesc,"2210: TECH ASST")) {AndyViewCr="Expenses:Salary:TA:TAUnknown";GBMFViewCr="Other Direct Costs:Computer Svc:TAUnknown"}
    if (match($FsrDesc,"2223: TECH ASST")) {AndyViewCr="Expenses:Salary:TA:TAUnknown";GBMFViewCr="Other Direct Costs:Computer Svc:TAUnknown"}
    if (match($FsrDesc,"02210 TA")) {AndyViewCr="Expenses:Salary:TA:TAUnknown";GBMFViewCr="Other Direct Costs:Computer Svc:TAUnknown"}
    }
  if(FsrExpenseCode == 5540) {AndyViewCr="Expenses:Subcontracts";GBMFViewCr="Other Direct Costs:SubAward"
    AndyViewCr="Expenses:Subcontracts:Unassigned";GBMFViewCr="Other Direct Costs:SubAward:Unassigned";
    if (match($FsrDesc,"RENSSELAER POLY SUBAWARD")) {AndyViewCr="Expenses:Subcontracts:RPI Subaward";GBMFViewCr="Other Direct Costs:SubAward:RPI SubAward"}
    }
  if(FsrExpenseCode == 5550) {AndyViewCr="Expenses:Publication Costs";GBMFViewCr="Other Direct Costs:Publications"}
  if(FsrExpenseCode == 5750) {AndyViewCr="Expenses:Salary:GuestPayments";GBMFViewCr="Labor and Benefits:GuestPayments"}
  if(FsrExpenseCode == 5960) {AndyViewCr="Expenses:Salary:GARegular";GBMFViewCr="Indirect Costs:General and Administrative"}
  if(FsrExpenseCode == 5966) {AndyViewCr="Expenses:Salary:GACasual";GBMFViewCr="Indirect Costs:General and Administrative"}
  if(FsrExpenseCode == 5970) {AndyViewCr="Expenses:CostSharing";GBMFViewCr="WHOI Cost Share"}
  #
  # Print WHOIView Transaction
  print substr(FsrDate,2,4) "/" substr(FsrDate,7,2) "/" substr(FsrDate,10,2) " " FsrExpenseCode " " FsrDesc
  Amount=FsrAmount
  if(minus) {gsub(/-/,"",Amount)} else {gsub(/^/,"-",Amount)}
  #print "  " FsrMainAccount FsrSubAccount ":WHOIView:Expenses:" FsrExpenseCode "		$" FsrAmount "  ; " FsrMemo
  #print  "  " FsrMainAccount FsrSubAccount ":WHOIView:Budget"
  print "  WHOIView:Expenses:" FsrExpenseCode "		$" FsrAmount "  ; " FsrMemo
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
