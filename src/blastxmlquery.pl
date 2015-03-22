#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my $xmlf = shift;
my $queryfile = shift;#juset 
my $multiSearch = shift;
my $splitNum    = shift;

my $queryType = "bylist";
my $queryStrs = getQueryList($queryfile);

if(!$queryStrs){
  if(!$splitNum or $splitNum < 1){
    print STDERR "usage:$0 blastxmlf queryfile[split] mutisearch splitNum\n";
    exit(1);
  }
  $queryType = "split";
}


open(IN,$xmlf) or die "cann't open xmlf file '$xmlf' due to:$!\n";
  my $query_start = 0;
  my $blastParam = 0;
  my $aQuery = "";
  my $num = 0;
  my $blastout = "";
  my $xmltitle = ""; 
  while(my $txt = <IN>){
    $xmltitle .= $txt if $txt =~ /^\s*<\?xml\s+/i;
    $xmltitle .= $txt if $txt =~ /^\s*<!DOCTYPE\s+/i;
    if($txt =~/^\s*<\/?(BlastOutput|Parameters).*>\s*$/){
      $blastout .= $txt;
    }
    if($txt =~ /^\s*<BlastOutput_iterations>\s*$/){
      if ($queryType eq 'bylist'){
        print $xmltitle,$blastout;
      }
    }
    if($txt =~ /^\s*<Iteration>\s*$/){
      $query_start = 1;
    }
    if($txt =~/^\s*<\/Iteration>\s*$/){
      $query_start = 0;
      $aQuery .= $txt;
      if ($queryType eq 'bylist'){
        if(my $i = isQueryInRetrieve($aQuery,$queryStrs)){
          $num++;
          print $aQuery;
          if (!$multiSearch){
            last if @$queryStrs == 1;
            splice(@$queryStrs,$i-1,1);
          }
        }
      }elsif($queryType eq 'split'){
        if ($num % $splitNum == 0){
          if ($num > 0){
            print OUT "</BlastOutput_iterations>\n</BlastOutput>\n";
            close(OUT) 
          }
          open (OUT, ">split" . int($num/$splitNum)) or die "Cann't open 'split' file in $num and $splitNum due to:$!\n";
          print OUT $xmltitle,$blastout;
        } 
        print OUT $aQuery;
        $num++;
      } 
      $aQuery = "";
    }
    $aQuery .= $txt if $query_start; 
  }
close(IN);

if ($queryType eq 'bylist'){
  print "</BlastOutput_iterations>\n</BlastOutput>\n";
}elsif($queryType eq 'split' ){
  print OUT "</BlastOutput_iterations>\n</BlastOutput>\n" if $num % $splitNum != 0;
}

print STDERR $num," queries finished\n";

sub isQueryInRetrieve{
  my $aQuery = shift;
  my $queryArray = shift;
  for(my $i=0;$i<@$queryArray;$i++){
    if($aQuery =~ /$queryArray->[$i]/){
      return $i+1 ;
    }
  }
  return 0;
}

sub getQueryList{
  my $f = shift;
  
  return undef if !$f ;
  return undef if !(-f $f);
  open(IN,$f) or die "Cann't open '$f' due to:$!\n";
    my @queryStr;
    my $i=0;
    while(my $txt = <IN>){
      $txt =~ s/^\s+//;
      $txt =~ s/\s+$//;
      $i++;
      if($txt && $txt !~ /^#/){
        my @f = split(/\s+/,$txt);
        if(@f == 2){
          push @queryStr,"<$f[0]>$f[1]" . '[^\w\-_]';
        }else{
          print STDERR "error format in line $i: $txt\n";
        }
      }
    }
  close(IN);
  return \@queryStr if @queryStr;
  return undef;
}

sub splitXML{

}
