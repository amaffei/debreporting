  # This gawk script ingests a files with WHOI FSR PPI records and crated a ledger
  # file from them
  BEGIN {
    #Define fields separator
    FPAT = "([^, ]+)|(\"[^\"]+\")"
    #Ledger Header at top of file
    print "; -*- ledger -*-"
    #Help for date conversion
    m=split("January|February|March|April|May|June|July|August|September|October|November|December",d,"|")
    for(o=1;o<=m;o++){
      months[d[o]]=sprintf("%02d",o)
    }
  format = "%m%d%Y"
  }
  
  /^"Personnel Pay Period Hours Detail/ { # 1st record in PPI block
    match($0,/ ([0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])( .* )For the /,arr)
    FsrAccountNumber=arr[1]
    FsrAccountName=arr[2]
    match($0,/period ending (.*) ([0-9]*),.*(2[0-9][0-9][0-9]).*$/,arr)
    FsrMonthName=arr[1]
    FsrMonth=months[FsrMonthName]
    FsrDay=arr[2]
    FsrYear=arr[3]
    #FsrYear=sub(/ /,//,FsrYear)
    #print "Fsr AccountNumber = " FsrAccountNumber "  Name = " FsrAccountName
    #print "Fsr MonthName = " FsrMonthName " Mon = " FsrMonth " Day = " FsrDay " Year = " FsrYear
    print FsrYear "/" FsrMonth "/" FsrDay " " FsrMonthName " " FsrYear " Work Hours"
    next
    }
  
  /^"Person ID","Name","Fiscal Period Regular Hours","Fiscal Period OT Hours","Fiscal Period Retro Hours","Fiscal Period Other Hours","Year To Date Regular Hours","Year To Date OT Hours","Year To Date Retro Hours","Year To Date Other Hours","Inception to Date Regular Hours","Inception to Date OT Hours","Inception to Date Other Hours"/ { # 2nd record in PPI block
    #print "Found Header"
    next
  }
  /"[0-9][0-9][0-9][0-9][0-9]"/ { # employee records in PPI block
    FsrPpiEmpno=sub(/"/,//,$1)
    match ($2,/"(.*), (.).*$/,arr)
    FsrPpiName=arr[1]
    prefix = "  WHOIView:WorkHours:" FsrPpiName ":"
    if (! ($3 == "0.00")) print prefix "Regular   " $3 " Hours" 
    if (! ($4 == "0.00")) print prefix "OT   " $4 " Hours"
    if (! ($5 == "0.00")) print prefix "Retro   " $5 " Hours"
    if (! ($6 == "0.00")) print prefix "Other   " $6 " Hours"
    #print $2 "(" $1 ")"
  }
  /"","Total",/ { # total record in PPI block
    prefix = "  WHOIView:WorkHoursAsset:"
    if (! ($3 == "0.00")) print prefix "Regular  -" $3 " Hours"
    if (! ($4 == "0.00")) print prefix "OT  -" $4 " Hours"
    if (! ($5 == "0.00")) print prefix "Retro  -" $5 " Hours"
    if (! ($6 == "0.00")) print prefix "Other  -" $6 " Hours"
  }
 
