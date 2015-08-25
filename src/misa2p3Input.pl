#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my $fasta = shift;
my $misa = shift;

my %SSR = getMisa($misa);

foreach my $scaf  (keys %SSR){
  #print($scaf . ":" . scalar(@{$SSR{$scaf}}) . "\n");
  #print($scaf,"\n");
}

my %parameters = ("product_min", 300,"product_max", 500, "primer_max_len", 30,"Flank",70);
#print Dumper(\%parameters);
#exit(0);

open(IN,$fasta) or die "can't open file '$fasta':$!\n";

my $seq = "";
my $seq_ID = "";
my @p3In1;
while(my $txt = <IN>){
  $txt =~ s/^\s+//;
  $txt =~ s/\s+$//;
  if($txt =~ /^>(\S+)/){
    if($SSR{$seq_ID}) {
      @p3In1 = generateP3Input($seq,$seq_ID,$SSR{$seq_ID},\%parameters);
      if (scalar(@p3In1) > 0) {
       print(join("\n",@p3In1),"\n");
      }
    } 
    $seq = "";
    $seq_ID = $1;
    print STDERR ($seq_ID,"\n");
    #last;
  }else{
    $seq .= $txt;
  }
}
close(IN);
if($SSR{$seq_ID}) {
  @p3In1 = generateP3Input($seq,$seq_ID,$SSR{$seq_ID},\%parameters);
  if (scalar(@p3In1) > 0) {
    print(join("\n",@p3In1),"\n");
  }
} 

sub generateP3Input {
  my $seq = shift;
  my $id  = shift;
  my $SSRs = shift;
  my $par = shift;
  
  my @result;
  foreach my $SSR (@$SSRs) {
    my $start = $SSR->[5] - $par->{"product_max"} + $par->{"primer_max_len"} + $SSR->[4] + 1;
    $start = 1 if $start <= 0;
    my $end = $SSR->[6] + $par->{"product_max"} - $par->{"primer_max_len"} - $SSR->[4] + 1;
    $end = length($seq) if $end > length($seq);

    my $target_left = $SSR->[5] - $par->{"Flank"} - $start;  
    next if $target_left <= 0;
    #$target_left = $SSR->[5] - $par->{"Flank"} - $start;  

    my $target_right = $SSR->[6] + $par->{"Flank"};
    next if $target_right >= length($seq); 
    $target_right = $SSR->[6] + $par->{"Flank"} - $start;
    
    $SSR->[3] =~ s/\).+\(/\-/g;
    $SSR->[3] =~ s/\).*//g;
    $SSR->[3] =~ s/.*\(//g;

    print STDERR (join(",",(@$SSR,$start,$end)),"\n") if $end - $start > 2 * $par->{"product_max"} + 500;
    push @result,"SEQUENCE_ID=".join("_",($SSR->[0],$SSR->[1],$SSR->[3],$SSR->[5],$SSR->[4]));
    push @result,"SEQUENCE_TEMPLATE=" . substr($seq,$start-1,$end-$start+1);
    push @result,"SEQUENCE_TARGET=" . $target_left . "," . ($target_right - $target_left + 1);
    push @result,"PRIMER_TASK=generic";
    push @result,"PRIMER_PICK_LEFT_PRIMER=1";
    push @result,"PRIMER_PICK_INTERNAL_OLIGO=0";
    push @result,"PRIMER_PICK_RIGHT_PRIMER=1";
    push @result,"PRIMER_OPT_SIZE=20";
    push @result,"PRIMER_MIN_SIZE=18";
    push @result,"PRIMER_MAX_SIZE=27";
    push @result,"PRIMER_MAX_NS_ACCEPTED=0";
    push @result,"PRIMER_PRODUCT_SIZE_RANGE=" . $par->{"product_min"} . "-" . $par->{"product_max"}; 
    push @result,"P3_FILE_FLAG=0";
    push @result,"SEQUENCE_INTERNAL_EXCLUDED_REGION=" . $target_left . "," . ($target_right - $target_left + 1);
    push @result,"PRIMER_EXPLAIN_FLAG=1";
    push @result,"=";
  }
  return(@result);
}

sub getMisa {
  my $misa = shift;
  
  open(IN,$misa) or die "Can't open misa file '$misa':$!\n";
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
