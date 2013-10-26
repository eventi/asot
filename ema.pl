#!/usr/bin/env perl
use Data::Dumper;
use Getopt::Std;
$| = 1;

my %options={};
getopts("pdc:i:",\%options);

# -c4

my $DEBUG = defined $options{d} ? 1 : 0;
my $passthru = defined $options{p} ? 1 : 0;
my $col = $options{c};
my $intervals = $options{i};

print "col:$col\n" if $DEBUG;

my $lastrow = "";
my $emaLast = 0;
while(<>){
	my $ema;
	if(/^#/){
		print $_ if $passthru;
	}else{
		print "#" . $_ if $passthru;
		chomp;
		###
		my @cols = split(/\t/);
		my $val = $cols[$col-1];
		if($emaLast == 0){
			$ema = $val;
		}else{
			my $k = 2/($intervals+1);
			$ema = $val * $k + $emaLast * (1-$k);
		}
		$lastrow = "$_\t$ema";
		print $lastrow . "\n";
		$emaLast = $ema;
	}
}
