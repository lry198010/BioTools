#!/usr/bin/perl -w
use strict;
use List::Util qw(sum min max);
use Getopt::Long;
use File::Basename;

my $fasta;
my $statFile = "";
my $distFile = "";
my $minLen = 200;

my $As = 0;
my $Ts = 0;
my $Gs = 0;
my $Cs = 0;
my $Ns = 0;

# Parameter variables
my $helpAsked;

GetOptions(
  "i=s" => \$fasta,
  "h|help" => \$helpAsked,
  "s|statOutputFile=s" => \$statFile,
  "d|distOutputFile=s" => \$distFile,
  "m|minLenStat=i" => \$minLen,
);

if(defined($helpAsked)) {
  prtUsage();
  exit;
}

if(!defined($fasta)) {
  prtError("No input files are provided");
}

if(not -f $fasta){
  prtError("file '$fasta' not exits");
  exit(1);
}

my ($fileName, $filePath) = fileparse($fasta);
$statFile = $fasta . "_n50_stat" if($statFile eq "");
$distFile = $fasta . "_dist" if($distFile eq "");

open(FI,$fasta) or die "Cann't open '$fasta' due to:$!\n";

my %seq;
my $nowSeqId="";
my $seq="";
while(my $txt = <FI>){
  if($txt !~ /^#/){
    $txt =~ s/^\s+//;
    $txt =~ s/\s+$//; 
    if($txt =~ /^>(\S+)/){
      if(length($seq) >= $minLen) {
        $seq{$nowSeqId} = length($seq);
        baseCount($seq);
      }
      $seq = "";
      $nowSeqId = $1;      
      if( defined $seq{$nowSeqId}){
        print STDERR "$nowSeqId is previous exist:$seq{$nowSeqId}\n";
      }
      #$seq{$nowSeqId} = 0;
    }else{
      $txt =~ s/\s//g;
      $seq .= $txt;
      #$seq{$nowSeqId} += length($txt);
    }
  }
}

if(length($seq) >= $minLen) {
  $seq{$nowSeqId} = length($seq);
  baseCount($seq);
}

close(FI);

my @len = values %seq;

my $totalReads = scalar @len;
my $bases = sum(@len);
my $minReadLen = min(@len);
my $maxReadLen = max(@len);
my $avgReadLen = sprintf "%0.2f", $bases/$totalReads;
my $medianLen = calcMedian(@len);
my $n25 = calcN50(\@len, 25);
my $n50 = calcN50(\@len, 50);
my $n75 = calcN50(\@len, 75);
my $n90 = calcN50(\@len, 90);
my $n95 = calcN50(\@len, 95);

open(O, ">$statFile") or die "Can not open file: $statFile\n";
print O "#only length >= $minLen used\n";

printf O "%-25s %d\n" , "Total sequences", $totalReads;
printf O "%-25s %d\n" , "Total bases", $bases;
printf O "%-25s %d\n" , "Min sequence length", $minReadLen;
printf O "%-25s %d\n" , "Max sequence length", $maxReadLen;
printf O "%-25s %0.2f\n", "Average sequence length", $avgReadLen;
printf O "%-25s %0.2f\n", "Median sequence length", $medianLen;
printf O "%-25s %d\n", "N25 length", $n25;
printf O "%-25s %d\n", "N50 length", $n50;
printf O "%-25s %d\n", "N75 length", $n75;
printf O "%-25s %d\n", "N90 length", $n90;
printf O "%-25s %d\n", "N95 length", $n95;
printf O "%-25s %0.2f %s\n", "As", $As/$bases*100, "%";
printf O "%-25s %0.2f %s\n", "Ts", $Ts/$bases*100, "%";
printf O "%-25s %0.2f %s\n", "Gs", $Gs/$bases*100, "%";
printf O "%-25s %0.2f %s\n", "Cs", $Cs/$bases*100, "%";
printf O "%-25s %0.2f %s\n", "(A + T)s", ($As+$Ts)/$bases*100, "%";
printf O "%-25s %0.2f %s\n", "(G + C)s", ($Gs+$Cs)/$bases*100, "%";
printf O "%-25s %0.2f %s\n", "Ns", $Ns/$bases*100, "%";

close(O);
print STDERR "Finished N50 Statisitcs output to file: $statFile\n";

open(O, ">$distFile") or die "Can not open file: $distFile\n";
print O "#only length >= $minLen used\n";
foreach my $k (keys %seq){
  print O "$k\t$seq{$k}\n";
}
close(O);

print STDERR "Finished sequence length  output to file: $distFile\n";
print STDERR "ok finished\n";

sub calcN50 {
  my @x = @{$_[0]};
  my $n = $_[1];
  @x=sort{$b<=>$a} @x;
  my $total = sum(@x);
  my ($count, $n50)=(0,0);
  for (my $j=0; $j<@x; $j++){
    $count+=$x[$j];
    if(($count>=$total*$n/100)){
      $n50=$x[$j];
      last;
    }
  }
  return $n50;
}

sub calcMedian {
  my @arr = @_;
  my @sArr = sort{$a<=>$b} @arr;
  my $arrLen = @arr;
  my $median;
  if($arrLen % 2 == 0) {
    $median = ($sArr[$arrLen/2-1] + $sArr[$arrLen/2])/2;
  }else{
    $median = $sArr[$arrLen/2];
  }
  return $median;
}

sub baseCount {
  my $seq = $_[0];
  my $tAs += $seq =~ s/A//gi;
  my $tTs += $seq =~ s/T//gi;
  my $tGs += $seq =~ s/G//gi;
  my $tCs += $seq =~ s/C//gi;
  #$Ns += (length $seq) - $tAs - $tTs - $tGs - $tCs;
  $Ns += (length $seq);# - $tAs - $tTs - $tGs - $tCs;
  $As += $tAs;
  $Ts += $tTs;
  $Gs += $tGs;
  $Cs += $tCs;
}

sub prtHelp {
  print "\nperl $0 options:\n\n";
  print STDERR "### Input reads/sequences (FASTA) (Required)\n";
  print STDERR "  -i <Read/Sequence file>\n";
  print STDERR "    Read/Sequence in fasta format\n";
  print STDERR "  -m <Min Sequence Length to Stat:200>\n";
  print STDERR "    Min Sequnece Length used in Stat\n";
  print STDERR "\n";
  print STDERR "### Other options [Optional]\n";
  print STDERR "  -h | -help\n";
  print STDERR "    Prints this help\n";
  print STDERR "  -s | -statOutputFile <Output file name>\n";
  print STDERR "    N50 output will be stored in the given file\n";
  print STDERR "    default: By default, N50 statistics file will be stored where the input file is\n";
  print STDERR "  -d | -distOutputFile <Output file name>\n";
  print STDERR "    Sequence length output will be stored in the given file\n";
  print STDERR "    default: By default, Sequence length file will be stored where the input file is\n";
  print STDERR "\n";
}

sub prtError {
  my $msg = $_[0];
  print STDERR "+======================================================================+\n";
  printf STDERR "|%-70s|\n", "  Error:";
  printf STDERR "|%-70s|\n", "       $msg";
  print STDERR "+======================================================================+\n";
  prtUsage();
  exit;
}

sub prtUsage {
  print STDERR "\nUsage: perl $0 <options>\n";
  prtHelp();
}
