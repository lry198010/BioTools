#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my $splignFile = shift;
my $identityThreshold = 1;
my $gapsThreshold = 0;

# The format of input file
#  0	1		2			3	4	5	6	7	8	9		10 			
# +1	lcl|mRNA_1	lcl|Ntab-K326_AWOJ-SS1	1	418	1	418	139948	140365	<exon>GT	M418
# +1	lcl|mRNA_1	lcl|Ntab-K326_AWOJ-SS1	1	328	419	746	141694	142021	AG<exon>	M328
# +2	lcl|mRNA_2	lcl|Ntab-K326_AWOJ-SS1	1	791	1	791	209203	209993	<exon>GT	M791
# +2	lcl|mRNA_2	lcl|Ntab-K326_AWOJ-SS1	1	126	792	917	211515	211640	AG<exon>GT	M126
# +2	lcl|mRNA_2	lcl|Ntab-K326_AWOJ-SS1	1	2083	918	3000	213006	215088	AG<exon>	M2083
# +3	lcl|mRNA_2	lcl|Ntab-K326_AWOJ-SS1487	-	40	1	40	-	-	<L-Gap>	-
# +3	lcl|mRNA_2	lcl|Ntab-K326_AWOJ-SS1487	0.933	778	41	791	195165	195941	AG<exon>GT	M3I2M5RM2RIMRM18RM5RM14RM3I6M16RM13RM36I3M72RM4RM4IM18I5M52RM11DM22R2M17I6M136I3M77RM20RM25R2M31RM26RM3RM5RM17RM8RM44RM18
# +3	lcl|mRNA_2	lcl|Ntab-K326_AWOJ-SS1487	0.937	126	792	917	197074	197199	AG<exon>GT	M5RM5RM20R2M4RM44RM2RM26RM12

open(FI,$splignFile) or die "Can not open file '$splignFile' due to:$!\n";
  my $mRNA = "";
  my @matchs;
  while (my $txt = <FI>) {
    if ($txt !~ /^#/) {
      my @fields = split(/\s+/, $txt); 
      if ($mRNA ne $fields[1]) {
        if (scalar(@matchs) > 0) {
          my $id = getBestMatch(\@matchs);
          # print join("\t",($mRNA,@$id)),"\n";
          my $bestMatch = getMatchById(\@matchs, $id->[0]);
          print join("\n",map {join("\t",@$_)} @$bestMatch),"\n";
        } 
        @matchs = ();
        $mRNA = $fields[1];
      }
      push @matchs, [@fields];
    }
  }

close(FI);

# return [id, numOfGaps, identity, numOfExon]
# there are should some other methods to determine the best match region:
#   the real identity, the average identity weighted by match length
sub getBestMatch {
  my $matchs = shift;
  
  #print Dumper($matchs); 
  my %gaps;
  my %identity;
  my %numOfExons;
  for (my $i = 0; $i < scalar(@$matchs); $i++) {
    if ($matchs->[$i]->[3] eq "-"){
      $gaps{$matchs->[$i]->[0]}++;
    } else {
      $identity{$matchs->[$i]->[0]} += $matchs->[$i]->[3]; 
      $numOfExons{$matchs->[$i]->[0]}++; 
    }
  }

  foreach my $k (keys %numOfExons) {
    $identity{$k} = $identity{$k}/$numOfExons{$k};
    if (!$gaps{$k}) {
      $gaps{$k} = 0;
    }
  }
  
  my @ids = sort {$gaps{$a} <=> $gaps{$b}} keys %gaps;
  my $bestKey = $ids[0];
  for (my $i = 1; $i <= $#ids; $i++) {  
    if ($gaps{$bestKey} == $gaps{$ids[$i]}) {
      if ($identity{$bestKey} < $identity{$ids[$i]}) {
        $bestKey = $ids[$i];
      }
    }else{
      ;
    }
  }
  return([$bestKey,$gaps{$bestKey},$identity{$bestKey}, $numOfExons{$bestKey}]);
}

sub getMatchById {
  my $matchs = shift;
  my $id = shift;
  return([grep { $_->[0] eq $id } @$matchs]);
}
