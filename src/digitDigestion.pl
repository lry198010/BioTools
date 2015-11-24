#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my $usage = "Perl $0 genome.fa enzyme.list\n";

# fa: genome sequence in fasta format
# enzyme: enzyme name and its reconized site, separated by table/space, one enzyme per line. for example:
# EcorI GAATTC
# HindIII AAGCTT
my $fa = shift;
my $enzyme = shift;

my %enzyme = getEnzyme($enzyme);

if (scalar(keys(%enzyme)) > 0) {
  my $enzyme_site = digeste($fa,\%enzyme); 
}

sub digeste {
  my $fa = shift;
  my $enzyme = shift;

  open(FI,$fa) or die "cann't open file '$fa':$!\n\t$usage";
    my %enzyme_site; 
    my $seq = "";
    my $seq_name = "";
    while (my $txt = <FI>) {
      $txt =~ /^\s+//;
      $txt =~ /\s+$//;
      if ($txt =~ /^>/){

      }else{

      }
    }
  close(FI);
}

sub digestion{
  my $seq = shift;
  my $enzyme = shift;
  
  my $pos = 0;
  
}

sub getComplementary {
  my $seq = shift;
  $seq = uc($seq);
  $seq =~ tr/ATCG/TAGC/;
  return scalar reverse $seq; 
}

sub getEnzyme {
  my $enzyme = shift;
  my %enzyme;
  
  open(FI,"$enzyme") or die "Cann't open file '$enzyme':$!\n\t$usage";
    while(my $txt = <FI>) {
      $txt =~ s/^\s+//;
      $txt =~ s/\s+$//;
      if ($txt !~ /^#/){
        my @enzinf = split(/\s+/,$txt);
        if (@enzinf == 2) {
          $enzyme{$enzinf[0]} = $enzinf[1];
        }
      }
    }
  close(FI);

  return(%enzyme);

}
