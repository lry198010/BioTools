#!/usr/bin/perl -w
use strict;
use Data::Dumper;

# todo
# 150902: more parameters from command line use opt package, include:
#   product_min
#   product_max
#   primer_max_len
#   primer_opt_len
#   primer_min_len
#   Flank

my $fasta = shift;
my $misa = shift;
# misa the position was start at 1, with the 1st base having position 1
# vcf the position of the ref was at 1, with the 1st base having position 1 

my $product_min = shift;
my $product_max = shift;
my $primer_min = shift;
my $primer_opt = shift;
my $primer_max = shift;
my $flank_l = shift;
my $flank_r = shift;

$product_min = 100 unless $product_min;
$product_min = 100 unless $product_min =~ /^[1-9]\d+$/;
$product_min += 0;

$product_max = 300 unless $product_max;
$product_max = 300 unless $product_max =~ /^[1-9]\d+$/;
$product_max += 0;

$product_max = $product_min + 200 if $product_min >= $product_max;

$primer_min = 18 unless $primer_min;
$primer_min = 18 unless $primer_min =~ /^[1-9]\d+$/;
$primer_min += 0;

$primer_opt = 20 unless $primer_opt;
$primer_opt = 20 unless $primer_opt =~ /^[1-9]\d+$/;
$primer_opt += 0;

$primer_max = 27 unless $primer_max;
$primer_max = 27 unless $primer_max =~ /^[1-9]\d+$/;
$primer_max += 0;

$primer_max = $primer_min if $primer_min > $primer_max;
$primer_opt = $primer_min if $primer_min > $primer_opt;
$primer_opt = $primer_max if $primer_opt > $primer_max;

$flank_l = 50 unless $flank_l;
$flank_l = 50 unless $flank_l =~ /^[1-9]\d+$/;
$flank_l += 0;

$flank_r = 50 unless $flank_r;
$flank_r = 50 unless $flank_r =~ /^[1-9]\d+$/;
$flank_r += 0;

print STDERR "Parameters:\n";
print STDERR "minimum product size:$product_min\n";
print STDERR "maximam product size:$product_max\n";
print STDERR "minimum primer length:$primer_min\n";
print STDERR "optimum primer length:$primer_opt\n";
print STDERR "maximal primer length:$primer_max\n";
print STDERR "left flank length:$flank_l\n";
print STDERR "right flank length:$flank_r\n";

my $usage = "Usage: perl $0 fasta_file misa_file product_min product_max primer_min primer_opt primer_max flank_left flank_right\n";

my %SSR = getMisa($misa);

#foreach my $scaf  (keys %SSR){
  #print($scaf . ":" . scalar(@{$SSR{$scaf}}) . "\n");
  #print($scaf,"\n");
#}

<<<<<<< HEAD
my %parameters = ("product_min", 500,"product_max", 1000, "primer_max_len", 30,"Flank",200);
=======
my %parameters = ("product_min", $product_min,"product_max", $product_max, "primer_min_len", $primer_min, "primer_opt_len", $primer_opt, "primer_max_len", $primer_max, "flank_left", $flank_l, "flank_right", $flank_r,"Flank",70);
>>>>>>> 03f69a5241facc7558f89c05beb3c6d5f876a61f
#print Dumper(\%parameters);
#exit(0);

open(IN,$fasta) or die "can't open file '$fasta':$!\n$usage";

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
    my $start = $SSR->[5] - $par->{"product_max"} + $par->{"primer_max_len"} + $SSR->[4] + $par->{'flank_left'};
    $start = 1 if $start <= 0;
    my $end = $SSR->[6] + $par->{"product_max"} - $par->{"primer_max_len"} - $SSR->[4] - $par->{'flank_right'};
    $end = length($seq) if $end > length($seq);

    my $target_left = $SSR->[5] - $par->{"flank_left"} - $start + 1;  
    next if $target_left <= 0;
    #$target_left = $SSR->[5] - $par->{"Flank"} - $start;  

    my $target_right = $SSR->[6] + $par->{"flank_right"};
    next if $target_right >= length($seq); 
    $target_right = $SSR->[6] + $par->{"flank_right"} - $start + 1;
    
    $SSR->[3] =~ s/\).+\(/\-/g;
    $SSR->[3] =~ s/\).*//g;
    $SSR->[3] =~ s/.*\(//g;

    print STDERR (join(",",(@$SSR,$start,$end)),"\n") if $end - $start > 2 * $par->{"product_max"} + 500;
    push @result,"SEQUENCE_ID=".join("_",($SSR->[0],$SSR->[1],$SSR->[3],$SSR->[5],$SSR->[4],$start));
    push @result,"SEQUENCE_TEMPLATE=" . substr($seq,$start-1,$end-$start+1);
    push @result,"SEQUENCE_TARGET=" . $target_left . "," . ($target_right - $target_left + 1);
    push @result,"PRIMER_TASK=generic";
    push @result,"PRIMER_PICK_LEFT_PRIMER=1";
    push @result,"PRIMER_PICK_INTERNAL_OLIGO=0";
    push @result,"PRIMER_PICK_RIGHT_PRIMER=1";
    push @result,"PRIMER_OPT_SIZE=" . $par->{"primer_opt_len"};
    push @result,"PRIMER_MIN_SIZE=" . $par->{"primer_min_len"};
    push @result,"PRIMER_MAX_SIZE=" . $par->{"primer_max_len"};
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
