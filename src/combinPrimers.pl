#!/usr/bin/perl -w
use strict;
use Data::Dumper;

# primer3 use 0-based position
my $misa = shift;
my $primerFile = shift;

my $usage = "perl $0 misa_file primerFile\n";

my %misas = getMisa($misa);

my $fromLeft = 50;
my $fromRight = 50;
open(FI,$primerFile) or die "cann't open file '$primerFile' due to:$!\n$usage";
  while(my $txt = <FI>){
    $txt =~ s/^\s+//;
    $txt =~ s/\s+$//;
    my @f = split(/\s+|_/,$txt);
    my $left = $f[7] + $f[5];
    my $right = $f[16] + $f[5];
    my @misaIn = combination($f[0],$left + $fromLeft, $right - $fromRight,\%misas);
    print STDERR scalar(@misaIn),":misaIn\n";
    print join("\t",@f),"\t";
    map {print join("\t",@{$_}),"\t";} @misaIn;
    print "\n";
    #print STDERR join("\t",($f[0],$f[1],$f[2],$f[5],$f[7],$f[16],$f[7] + $f[5] - 1, $f[16] + $f[5] - 1)),"\n";    
  }
close(FI);

sub combination{
  my $chr = shift;
  my $left = shift;
  my $right = shift;
  my $misas = shift;
  
  my @result;
  if($misas->{$chr}) {
    foreach my $amisa (@{$misas->{$chr}}){
      if($amisa->[5] >= $left && $amisa->[6] <= $right) {
        push @result,$amisa;
      }
    }
  } 
  return(@result);
}

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
