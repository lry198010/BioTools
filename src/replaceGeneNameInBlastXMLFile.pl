#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my $xml = shift;
my $IDtable = shift;
my $keyCol = shift;
my $valCol = shift;

my $usage = "$0 <xmlfile> <IDtable> key_col[0] value_col[1]\n";

my $ids = getIDs($IDtable,$keyCol,$valCol);

open(FI,$xml) or die "cann't open xml file '$xml':$!\n";
  while (my $txt = <FI>){
    if ($txt =~ /<Iteration_query-def>(\S+)/) {
       if ($ids->{$1}){
          my $v = $ids->{$1};
          $txt =~ s/(<Iteration_query-def>)(\S+)/$1$v/;
       }else{
          print STDERR "warning:$1 not transform\n";
       }
    }
    print $txt;
  } 
close(FI);

sub getIDs {
  my $idfile = shift;
  my $kc = shift; # the column number of the key
  my $vc = shift; # the column number of the value
  
  my %r;
  open(FI,"$idfile") or die "Cann't open id file '$idfile':$!\n";
    while (my $txt = <FI>) {
      my @f = split(/\s+/,$txt);
      if (!$r{$f[$kc]}){
        $r{$f[$kc]} = $f[$vc];
      }
    }
  close(FI);
  return(\%r); 
}
