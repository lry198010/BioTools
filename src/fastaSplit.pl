#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my $fasta = shift; 
my $splitNum = shift;
my $random = shift;
my $spname = shift;
            
unless ($fasta){
  print STDERR "usage:$0 fastafile splitNum[# of reads per file] random[1|0] spname[sufix]\n";
  exit(1);
}

my $queryType = "split";
$spname = $fasta . ".sp" unless defined $spname;

$random = 1 unless defined $random;

print STDERR "from file: $fasta\nsNumber of reads per file:$splitNum\nsuffix name:$spname\nRandom assign[1=yes]:$random\n";

if( (!$splitNum) or ($splitNum < 1)){
  print STDERR "splitNum error:$splitNum\n";
  print STDERR "usage:$0 fastafile splitNum[# of reads per file] random[1|0] spname[sufix]\n";
  exit(1);
}       

if ($random) {
  my @seqs = getAllFastaSeq($fasta);
  print STDERR "number of sequences:",scalar(@seqs),"\n";
  #print $seqs[int(rand(scalar(@seqs)-1))];
  my @sortRandom = randomSeqs(scalar(@seqs));
  for (my $i = 0; $i < scalar(@seqs); $i++) {
    if ($i % $splitNum == 0) {
      print STDERR $i,"\n";
      if($i > 0){
        close(OUT);
      } 
      open(OUT,">$spname".(int($i/$splitNum))) or die "Cann't open file '$spname'" . int($i/$splitNum) . "due to:$!\n";
    }
    print OUT $seqs[$sortRandom[$i]];
  }
  close(OUT);
} else {
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
}
   
sub getQueryList{
  return undef;
}

sub getAllFastaSeq {
  my $f = shift;
  my @seqs;
  open(FIN,$f) or die "Cann't open fasta file '$f':$!\n";
    my $i = -1;
    while (my $txt = <FIN>) {
      $txt =~ s/^\s+//;
      if ($txt =~ /^>/) {
        $i++;
        $seqs[$i] = ""; 
      }
      $seqs[$i] .= $txt;
    }
  close(FIN);
  return(@seqs);
}

sub randomSeqs {
  my $num = shift;
  
  my @randoms;
  
  for (my $i = 0; $i < $num; $i++) {
    push @randoms,[$i,int(rand($num * 20))];
  } 
    
  @randoms = sort {$a->[1] <=> $b->[1];} @randoms; 
  @randoms = map {$_->[0]} @randoms;
  return(@randoms);
}
