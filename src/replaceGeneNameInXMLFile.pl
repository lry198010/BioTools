#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my $xml = shift;
my $match = shift;
my $IDtable = shift;
my $keyCol = shift;
my $valCol = shift;

my $usage = "$0 <xmlfile> <Matchpattern>['(<Iteration_query-def>\\s*)(\\S+)()'] <IDtable> key_col[0] value_col[1]\n";

$match = '(<Iteration_query-def>\s*)(\S+)()' unless $match;
# $replaceMatch = "(<Iteration_query-def>)(\\S+)" unless $replaceMatch;
# $match = '(<xref\s*id=")(\S+)(")' unless $match; # for interposcan xml result
my $ids = getIDs($IDtable,$keyCol,$valCol);

print STDERR $match,"\n";

open(FI,$xml) or die "cann't open xml file '$xml':$!\n$usage";
  while (my $txt = <FI>){
    if ($txt =~ /$match/) {
       if ($ids->{$2}){
         $txt = substr( $txt, 0, $-[0] ) . $1 . $ids->{$2} . $3 . substr( $txt, $+[0] );
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
