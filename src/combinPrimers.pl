#!/usr/bin/perl -w
use strict;
use Data::Dumper;

# primer3 use 0-based position
my $misa = shift;
my $primerFile = shift;
my $primers2Considered = shift;

my $usage = "perl $0 misa_file primerFile primers2Considered[5]\n";

$primers2Considered =  5 if !(defined($primers2Considered)) || $primers2Considered !~ /^\d+$/ || $primers2Considered < 1;

my @misas = getArraybyFile($misa);
my @primers = getArraybyFile($primerFile,$primers2Considered);

print STDERR "misa (targets):",scalar(@misas),"\tprimers pairs:",scalar(@primers),"\n";
#print Dumper(@misas);
#print Dumper(@primers);
#exit(0);

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


#print STDERR Dumper(\%primers);

my %selectedPrimers;
my $id = getMaxMisaInPrimers(\%primers);
while(defined ($id) ) {
  $selectedPrimers{$id} = delete($primers{$id});
  print STDERR "$id:id\n";
  adjustPrimers($id,$selectedPrimers{$id},\%primers,\%misas); 
  $id = getMaxMisaInPrimers(\%primers);
}

# print STDERR Dumper(\%selectedPrimers);

foreach my $p (keys %selectedPrimers) {
  next unless defined $p;
  foreach my $m (@{$selectedPrimers{$p}}) {
    next unless defined $m;
    #print STDERR "p:$p,m:$m\n";
    print join("\t",(@{$misas[$m]},@{$primers[$p]})),"\n";
  }
}

# print "primers:\n";
# print Dumper(\%primers);
# print "misas:\n";
# print Dumper(\%misas);
# print "selectPrimers:\n";
# print Dumper(\%selectedPrimers);


sub getMaxMisaInPrimers {
  my $primers = shift;
  
  my $id = "";
  my $num = 0;
  my @ids;
  foreach my $k (keys %{$primers}) {
    my $i = 0;

    foreach my $v (@{$primers->{$k}}) {
      $i++ if defined($v);
    }
    
    delete($primers->{$k}) if $i == 0;

    if ( $i > $num) {
      $id = $k;
      $num = $i;
      @ids = ($k);
    }elsif ($i == $num) {
      push @ids,$k;
    }
  }
  
  return undef if $num == 0;
  #print STDERR join(",",@ids),"\n";
  #print STDERR join(",",(sort {$a<=>$b;} @ids)),"\n";
  ($id) = sort {$a<=>$b;} @ids;
  return $id;
}

sub adjustPrimers {
  my $id = shift;
  my $selectedMisas = shift;
  my $primers = shift;
  my $misas = shift;
  
  #print STDERR scalar(@$selectedMisas),":selectedmisas\n";
  #print STDERR join(",",@$selectedMisas),"\n";
  foreach my $amisa (@$selectedMisas) {
    next unless defined($amisa);
    my $misaPrimers = delete($misas->{$amisa});  
    #print $amisa,":misa\n";
    #print Dumper($misaPrimers);
    foreach my $aprimer (@$misaPrimers){ 
      next if $id == $aprimer;
      #print $aprimer,":primer\n";
      #print "scalar aprimers contain misa:",scalar(@{$primers->{$aprimer}}),"\n";
      #print Dumper($primers->{$aprimer});
      for ( my $i = 0; $i < scalar(@{$primers->{$aprimer}}); $i++) {
        $primers->{$aprimer}->[$i] = undef if ( defined ($primers->{$aprimer}->[$i]) && ($primers->{$aprimer}->[$i] == $amisa)); 
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
  my $num2Get = shift; # max number of arrays return, the array all have the same title  

  $num2Get = 100000000 if !(defined($num2Get)) || $num2Get !~ /^\d+$/ || $num2Get < 1;
  #print STDERR $num2Get,":num2get\n";
  open(IN,$arrayFile) or die "Can't open misa file '$arrayFile':$!\n$usage";
  print STDERR "Begin read data from:$arrayFile\n";
  my @result;
  my $i = 0;
  my $name = "";
  my $numGetted = 0;
  while(my $txt = <IN>){
    $txt =~ s/^\s+//;
    $txt =~ s/\s+$//;
    if($txt !~ /SSR.+type.+size.+start.+end$/){
      my @f = split(/\s+/,$txt);
      $i++;
      print STDERR ("read Arrays:" . $i . "\n") if $i % 1000 == 0;
      if ( $f[0] ne $name ) {
        $numGetted = 0;
        $name = $f[0];
      }
      if ($numGetted < $num2Get) {
        push @result,[@f];
        $numGetted++;
      }
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
