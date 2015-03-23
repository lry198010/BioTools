#!/usr/bin/perl -w
use strict;
use List::Util qw(first max min);
use Data::Dumper;

my $usage = "\tperl $0 cuffdiff[cuff difference file] mergeFile[gtf format from cuffmerge] threshold[0.05,significant]\n";
if($#ARGV < 1 ){
  print STDERR "More Argument required\n";
  print STDERR "Useage:\n";
  print STDERR $usage;
  exit(1);
}

my $cdFile = shift; #cuff_diff file
my $mergeFile = shift; # merge.file, with gene_id and responsed gene name from gff
my $threshold = shift;# 

$threshold = 0.05 unless defined $threshold;

# Format for cdFile
# test_id     gene_id     gene locus              sample_1 sample_2 status value_1 value_2 log2(fold_change) test_stat p_value q_value significant
# 0           1           2    3                  4        5        6      7       8       9                 10        11      12      13
# XLOC_000001 XLOC_000001 -    chrA01:823-2436    n1       n2       OK	   22.5379 31.3485 0.476044          1.0035    0.14865 0.26623 no
# XLOC_000002 XLOC_000002 -    chrA01:8420-9623	  n1       n2       NOTEST 0       0       0                 0         1       1       no
# XLOC_000003 XLOC_000003 -    chrA01:18235-19430 n1       n2       OK     0.57963 1.94315 1.74519           2.15934   0.0061  0.02114 yes
# XLOC_000004 XLOC_000004 -    chrA01:24702-26339 n1       n2       OK     0.90219 3.98274 2.14226           2.33177   0.0003  0.00187 yes


my ($geneRels,$novoGenes) = getGeneIdsRelation($mergeFile);

open(FI,"$cdFile") or die "open file '$cdFile' error:$!\n$usage";
  while (my $txt = <FI>) {
    if ($txt !~ /^#/){
      my @fields = split(/\s+/,$txt); 
      if ($fields[12] <= $threshold) {
        if ($geneRels->{$fields[1]}) {
          foreach my $id (@{$geneRels->{$fields[1]}}){
            print join("\t",(@fields[1,4,5,12], $id)),"\n";
          }
        } 
      }
    }
  }
close(FI);
# format for merge gtf file
# chrA01  Cufflinks       exon    824     926     .       +       .       gene_id "XLOC_000001"; transcript_id "TCONS_00000001"; exon_number "1"; oId "CUFF.2.1"; nearest_ref "BnaA01g00010D"; class_code "o"; tss_id "TSS1";
# chrA01  Cufflinks       exon    1068    1574    .       +       .       gene_id "XLOC_000001"; transcript_id "TCONS_00000001"; exon_number "2"; oId "CUFF.2.1"; nearest_ref "BnaA01g00010D"; class_code "o"; tss_id "TSS1";
# chrA01  Cufflinks       exon    831     1437    .       +       .       gene_id "XLOC_000001"; transcript_id "TCONS_00000002"; exon_number "1"; oId "BnaA01g00010D"; nearest_ref "BnaA01g00010D"; class_code "="; tss_id "TSS1"; p_id "P1";

sub getGeneIdsRelation {
  my $mergeFile = shift;
  
  my %geneRels;
  my %novoGenes;
  
  open(FI,$mergeFile) or die "$!\n$usage";
    while(my $txt = <FI>){
      if ($txt !~ /^#/){
        if ($txt =~ /gene_id\s\"([\w_\d]+).+nearest_ref\s\"([\w\d]+)/) {
          if ($geneRels{$1}) {
             if (!(defined (first {$_ eq $2} @{$geneRels{$1}}))) {
               push  @{$geneRels{$1}},$2;
             }  
          } else {
             $geneRels{$1} = [$2];
          }
        } elsif ($txt =~ /gene_id\s\"([\w_\d]+)/) {
          $novoGenes{$1}++;
        }
      }

    } 
  close(FI);
  
  return (\%geneRels,\%novoGenes);
}
