#!/usr/bin/env perl
use Data::Dumper;
use Getopt::Std;
$| = 1;

my %options={};
getopts("pdm:e:",\%options);

# -c4,5

my $DEBUG = defined $options{d} ? 1 : 0;
my $passthru = defined $options{p} ? 1 : 0;
my $macd_c = $options{m};
my $ema_c = $options{e};

print "macd col: $macd_c\tema col: $ema_c\n" if $DEBUG;

while(<>){
	if(/^#/){
		print $_ if $passthru;
	}else{
		print "#" . $_ if $passthru;
		chomp;
		my @c = split(/\t/);
		print "\@c:" . Dumper(@c) if $DEBUG;
		my $macd = $c[$macd_c-1];
		my $ema9 = $c[$ema_c-1];
		my $div  = $macd-$ema9;
		my $strat = "HOLD";
		print "macd: $macd\tema: $ema\tdiv: $div\n" if $DEBUG;
		if($macd < 0){
			$strat = "SELL";
		}else{
			if($macd > 0){
				if ($ema9 > 0){
					$strat = "BUY";
				}
			}
		}
		print "$_\t$strat\n";
	}
}
