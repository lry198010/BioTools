#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my $fasta = shift; 
my $splitNum = shift;
my $spname = shift;
            
unless ($fasta){
  print STDERR "usage:$0 fastafile splitNum spname\n";
  exit(1);
}

print STDERR "split:$splitNum\n";

my $queryType = "split";
$spname = $fasta . ".sp" unless $spname;
      
if( (!$splitNum) or ($splitNum < 1)){
  print STDERR "splitNum error:$splitNum\n";
  print STDERR "usage:$0 fastafile splitNum spname\n";
  exit(1);
}       
        
open(IN,$fasta) or die "Cann't open fasta file '$fasta' due to:$!\n";
  my $seq = "";
  my $num = 0;
  while(my $txt = <IN>){
    if($txt !~ /^#/){
      if($txt =~ /^>/){
        if($num % $splitNum == 0){
          if($num > 0){
            close(OUT);
          } 
          open(OUT,">$spname".(int($num/$splitNum))) or die "Cann't open file '$spname'" . int($num/$splitNum) . "due to:$!\n";
        }
        $num++;
      } 
      print OUT $txt;
    } 
  }   
close(IN);
   
sub getQueryList{
  return undef;
}
