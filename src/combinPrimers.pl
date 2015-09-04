#!/usr/bin/perl -w
use strict;
use Data::Dumper;

# primer3 use 0-based position
my $misa = shift;
my $primerFile = shift;

my $usage = "perl $0 misa_file primerFile\n";

my @misas = getArraybyFile($misa);
my @primers = getArraybyFile($primerFile);

print "misa:",scalar(@misas),"\tprimers:",scalar(@primers),"\n";
print Dumper($misas[0]);
print Dumper($primers[0]);

my $fromLeft = 50;
my $fromRight = 50;

my %misas;
my %primers;
for ( my $i = 0; $i < scalar(@primers); $i++) {

  my @chrinfor = split(/_/,$primers[$i]->[0]);
  my $left = $primers[$i]->[2] + $chrinfor[5] + $fromLeft;
  my $right = $primers[$i]->[11] + $chrinfor[5] - $fromRight;

  for ( my $j = 0; $j < scalar(@misas); $j++) {
    if ($misas[$j]->[0] eq $chrinfor[0]){
      if ($misas[$j]->[5] >= $left && $misas[$j] ->[6] <= $right) {
        if ($primers{$i}) {
          push @{$primers{$i}},$j;
        }else{
          $primers{$i} = [$j];
        }
        
        if ($misas{$j}) {
          push @{$misas{$j}}, $i;
        }else{
          $misas{$j} = [$i];
        } 
      } 
    }
  }

}

my %selectedPrimers;
my $id = getMaxMisaInPrimers(\%primers);
while(defined ($id) ) {
  $selectedPrimers{$id} = delete($primers{$id});
  print "$id:id\n";
  adjustPrimers($id,$selectedPrimers{$id},\%primers,\%misas); 
  $id = getMaxMisaInPrimers(\%primers);
}


print Dumper(\%primers);
print Dumper(\%misas);

sub getMaxMisaInPrimers {
  my $primers = shift;
  
  my $id = "";
  my $num = 0;
  foreach my $k (keys %{$primers}) {
    my $i = 0;

    foreach my $v (@{$primers->{$k}}) {
      $i++ if defined($v);
    }

    if ( $i > $num) {
      $id = $k;
      $num = $i;
    }
  }
  
  return undef if $num == 0;
  return $id;
}

sub adjustPrimers {
  my $id = shift;
  my $selectedMisas = shift;
  my $primers = shift;
  my $misas = shift;
  
  foreach my $amisa (@$selectedMisas) {
    my $misaPrimers = delete($misas->{$amisa});  
    print $amisa,":misa\n";
    print Dumper($misaPrimers);
    foreach my $aprimer (@$misaPrimers){ 
      next if $id == $aprimer;
      print $aprimer,":primer\n";
      for ( my $i = 0; $i < scalar(@{$primers->{$aprimer}}); $i++) {
        $primers->{$aprimer}->[$i] = undef if $primers->{$aprimer}->[$i] == $amisa; 
      }
    }
  }
}

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

sub getArraybyFile {
  my $arrayFile = shift;

  open(IN,$arrayFile) or die "Can't open misa file '$arrayFile':$!\n$usage";
  my @result;
  my $i = 0;
  while(my $txt = <IN>){
    $txt =~ s/^\s+//;
    $txt =~ s/\s+$//;
    if($txt !~ /SSR.+type.+size.+start.+end$/){
      my @f = split(/\s+/,$txt);
      push @result,[@f];
      $i++;
      print STDERR ("read SSR:" . $i . "\n") if $i % 1000 == 0;
    }
  }    
  close(IN);
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
