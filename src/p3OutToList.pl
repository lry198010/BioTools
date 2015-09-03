#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my $p3Out = shift;

open(IN,$p3Out) or die "Cann't open primer3 out file '$p3Out' due to:$!\n";
  my $primerName = "";
  my @result;
  my $tmp = "";
  while (my $txt = <IN>) {
    $txt =~ s/^\s+//;
    $txt =~ s/^\d+//;
    $txt =~ s/^\s+//;
    $txt =~ s/\s+$//;
    if ($txt =~ /PRIMER|PRODUCT/) {
      if($txt =~ /RESULTS.*\s(\S+)/){
        print STDERR "primers for marker:",$1,"\n";
        $primerName = $1; 
      }elsif($txt =~ /LEFT|RIGHT/){
        $txt =~ s/PRIMER\s*//;
        $txt =~ s/\s+/\t/g;
        $tmp .= "\t" . $txt
      }elsif($txt =~ /PRODUCT/) {
        my @f = split(/,|:/,$txt);
        $tmp .= join("",@f[1,3,5]);
        $tmp = $primerName . "\t" . $tmp;
        $tmp =~ s/\s+/\t/g;
        push @result,$tmp;
        #push @result,$primerName . "\t" . $tmp;
        $tmp = "";
        #$primerName = ""; 
      }else{
        print STDERR "unreconized items:$txt\n";
      }
    }
  }
close(IN);

print join("\n",@result);

sub getMisa {
  my $misa = shift;
  
  open(IN,$misa) or die "Can't open misa file '$misa':$!\n$usage";
  my %result;
  my $i = 0;
  while(my $txt = <IN>){
    $txt =~ s/^\s+//;
    $txt =~ s/\s+$//;
    if($txt !~ /SSR.+type.+size.+start.+end$/){
      my @f = split(/\s+/,$txt);
      if($result{$f[0]}){
        push $result{$f[0]},[@f];
      }else{
        $result{$f[0]} = [[@f]];
      }
      $i++;
      print STDERR ("read SSR:" . $i . "\n") if $i % 1000 == 0;
    }
  }    
  close(IN);
  return(%result);
}
