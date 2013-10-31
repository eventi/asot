#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper qw(Dumper);
use Getopt::Std;
$| = 1;

#How much below ZERO can div dip before SELL?
my $divdip = 0.1;
#	pct of macd? fixed?
#How much above ZERO can macd rise before BUY?
my $macrise = 0.1;
#	pct of avg? fixed?
#How much above ZERO can div rise before BUY?
my $divrise = 0.1;
#	pct of avg? fixed?
#how many signals before acting?
my $signals = 1;
#long and short ema values?

my %options;
getopts("pdm:e:a:",\%options);

# -c4,5

my $DEBUG = defined $options{d} ? 1 : 0;
my $passthru = defined $options{p} ? 1 : 0;
my $avg_c = $options{a} || 0;
my $macd_c = $options{m};
my $div_c = $options{e};

if ( scalar(@ARGV) == 4 ) {
	($divdip,$macrise,$divrise,$signals) = @ARGV;
}

print Dumper($divdip,$macrise,$divrise,$signals) if $DEBUG;

print "macd col: $macd_c\tdiv col: $div_c\n" if $DEBUG;

my $laststrat = "BOGUS";
my $samesignal = 0;

while(<STDIN>){
	if(/^#/){
		print $_ if $passthru;
	}else{
		print "#" . $_ if $passthru;
		chomp;
		my @c = split(/\t/);
		print "\@c:" . Dumper(@c) if $DEBUG;
		my $macd = $c[$macd_c-1];
		my $div  = $c[$div_c-1];
		my $avg  = $c[$avg_c-1];
		my $strat = "HOLD";
		print "macd: $macd\tdiv: $div\n" if $DEBUG;
		if($div < -$divdip){
			$strat = "SELL";
		}else{
			if($macd > $macrise){
				if ($div > $divrise){
					$strat = "BUY";
				}
			}
		}
		if($laststrat eq $strat){
			$samesignal++;
		}else{
			$laststrat = $strat;
			$samesignal = 1;
		}
		if ($samesignal < $signals){
			$strat = "HOLD";
		}
		print "$_\t$strat\n";
	}
}
