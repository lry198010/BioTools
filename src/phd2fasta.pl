#!/usr/bin/perl -w
use strict;

my $usage = "perl $0 phdfile outputfile QualOut[1|0]\n";

my $phd = shift;

if (not (-e $phd)) 
{
  print STDERR "phd file '$phd' is not exist\n";
  print $usage; 
}

open (IN,$phd) or die "Cann't open phd file '$phd':$!\n";
 my $Begin = 0;
 my $seq = "";
 my $qual = "";
 while (my $txt = <IN>){
   $txt =~ s/^\s+//;
   $txt =~ s/\s+$//;
   if ($txt eq 'BEGIN_DNA') {
     $Begin = 1;
   }elsif($txt =~ /END_DNA/) {
     $Begin = 0;
   }elsif($Begin == 1){
     my @f = split(/\s+/,$txt);
     if (@f == 3) {
       $seq .= $f[0];
       $qual .= $f[1];
     }
   }
 }
close(IN); 

 
my $outfile = shift;
my $qualfile = "";

if (not defined $outfile) {
  $outfile = $phd . ".fa";
}

$phd =~ s/.*\///;

#open(OUT,">$outfile") or die "Cann't open fa file '$outfile':$!\n";
print ">$phd\n$seq\n";
#close(OUT);
