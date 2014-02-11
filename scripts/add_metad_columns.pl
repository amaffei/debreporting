#!/usr/bin/env perl
#!/usr/bin/perl
#
# (c)2014 The Visual Connection
#
# Description: Adds metadata columns to an input CSV based on patterns 
#              given in a sequential list of matchfiles
#
# Usage: add_metad_columns.pl <-i input.csv | stdin> <-m matchfile1,matchfile2,...> <-o outfile.csv | stdout> [-d]
#
# Eample input.csv (as table)
#
#     ExpCode   ExpDesc                                EmpID   Amount
#    ---------+--------------------------------------+-------+--------
#       5010    Salary for week of 1/1/2014             1234    10.00
#       5010    Salary for week of 1/1/2014             6789    11.00
#       5170    Plane ticket to LAX for AMAFFEI          N/A   600.00
#       5170    Hotel room in Los Angeles for Maffei     N/A   300.00
#       5170    PO for conference                       1234   150.00
#
# Example <matchfile> represented as a table
#      M_Col1   M_Str1   M_Col2    M_Str2   AndyView        OrgView
#     ---------+--------+---------+--------+---------------+--------------------------
#      ExpCode     5010   EmpID       1234   Salary:Maffei   Expenses:Salary:AndrewM
#      ExpCode     5010   EmpID       6789   Salary:Lerner   Expenses:Salary SteveL
#      ExpCode     5170   ExpDesc   Maffei   Travel:Maffei   Expenses:LATrip:Hotel
#      ExpCode     5170   EmpID       1234   Travel:Maffei   Expenses:LATrip:RVTECFee
#
# 
# Example <output.csv> represented as a table
#      ExpCode   ExpDesc                                EmpID   Amount   AndyView        OrgView
#     ---------+--------------------------------------+-------+--------+---------------+--------------------------
#        5010   Salary for week of 1/1/2014             1234    10.00   Salary:Maffei   Expenses:Salary:AndrewM
#        5010   Salary for week of 1/1/2014             6789    11.00   Salary:Lerner   Expenses:Salary SteveL
#        5170   Plane ticket to LAX for Maffei           N/A   600.00   Travel:Maffei   Expenses:LATrip:Plane
#        5170   Hotel room in Los Angeles for Maffei     N/A   300.00   Travel:Maffei   Expenses:LATrip:Hotel
#        5170   PO for LA conference registration       1234   100.00   Travel:Maffei   Expenses:LATrip:RVTECFee
#
#====================================================================================

use strict;
require "getopts.pl";

my $VERSION = "v1.0-20140109";
my $DEBUG = 0;

my $infile;
my $matchfile;
my $outfile;

our($opt_i, $opt_m, $opt_o, $opt_d);

&Getopts('i:m:o:d');
if ($opt_i) {$infile    = $opt_i;}
if ($opt_m) {$matchfile = $opt_m;}
if ($opt_o) {$outfile   = $opt_o;}
if ($opt_d) {$DEBUG = 1;}

if ($infile eq "" || $matchfile eq "" || $outfile eq "")
    {print "$0 - $VERSION\n";
     print "Usage: $0 <-i input.csv | stdin> <-m matchfile1,matchfile2,...> <-o outfile.csv | stdout> [-d]\n\n";
     exit(-1);
     }

if ($DEBUG)
  {print "Input  CSV file: $infile\n";
   print "Match  CSV file: $matchfile\n";
   print "Output CSV file: $outfile\n\n";
   }

#
# Make sure we can open input files and write outfile
#
my($inFD, $matchFD, $outFD);
if ($infile eq "stdin")  {$inFD = *STDIN;}
                    else {open($inFD,"<$infile")    || die "Error opening infile [$infile]\n";}
if ($outfile eq "stdout") {$outFD = *STDOUT;}
                     else {open($outFD,">$outfile") || die "Error: unable to write output file [$outfile]\n";}
open($matchFD,"<$matchfile") || die "Error opening matchfile [$matchfile]\n";


#
# Read-in incsv and matchcsv files
#
my @InLines  = <$inFD>;
my $InHdr    = $InLines[0]; chomp($InHdr);

my @MatchLines = <$matchFD>; 
my $MatchHdr   = $MatchLines[0]; chomp($MatchHdr);
my ($mcol1,$mstr1,$mcol2,$mstr2,$mviews) = split(',',$MatchHdr,5);
my @mview_list = split(',',$mviews);
# print $outFD "$InLines[0],$mviews\n";
print $outFD "$InHdr,$mviews\n";  # ARM

my($i,$j);
for ($i=1; $i<=$#InLines; $i++)
  {chomp($InLines[$i]);
   my $newcols = "";
   my %InCsv = parseCSV($InHdr,$InLines[$i]);
   for ($j=1; $j<=$#MatchLines; $j++)
     {my %MatchCsv = parseCSV($MatchHdr,$MatchLines[$j]);
      my $mf1 = $MatchCsv{"$mcol1"};
      my $ms1 = $MatchCsv{"$mstr1"};
      my $mf2 = $MatchCsv{"$mcol2"};
      my $ms2 = $MatchCsv{"$mstr2"};
      #TBD - do exact match or partial match or hybrid
      #if ($InCsv{"$mf1"} eq "$ms1" &&
      #    $InCsv{"$mf2"} eq "$ms2")
      #if ($InCsv{"$mf1"} =~ /$ms1/i &&
      #    $InCsv{"$mf2"} =~ /$ms2/i)
      if ($InCsv{"$mf1"} eq "$ms1" &&
          $InCsv{"$mf2"} =~ /$ms2/i)
           {if ($DEBUG)
              {print "inlinecnt=$i, InCsv[$mf1] eq $ms1 && InCsv[$mf2] =~ $ms2\n";}
            #Add the mviews columns
            foreach my $mview (@mview_list)
              {$newcols .= ",$MatchCsv{\"$mview\"}";
               }
            last;
            }
      }
   print $outFD "$InLines[$i]$newcols\n";
   }


close($inFD);
close($matchFD);
close($outFD);

exit;


#
# Subroutines Follow
#
sub parseCSV {my($hdr_line) = $_[0];
              my($line)     = $_[1];
   my(%Csv);
   my @field = split(',',$hdr_line);
   my $i;

   chomp($line);
   my (@val) = split(',',$line);
   for ($i=0; $i<=$#val; $i++)
      {$val[$i] =~ s/^(\s+)//; #remove leading spaces
       $val[$i] =~ s/(\s+)$//; #remove trailing spaces
       $Csv{"$field[$i]"} = "$val[$i]";
       #print "Csv[$field[$i]] = $val[$i]\n";
       }
   return %Csv;
}
