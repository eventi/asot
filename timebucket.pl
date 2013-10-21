#!/usr/bin/env perl
use Getopt::Std;
my %options={};
getopts("s:dz",\%options);

my $DEBUG = defined $options{d} ? 1 : 0;
my $bucketsize = defined $options{s} ? $options{s} : 1000*1000; # one second
my $sparse = defined $options{z} ? 1 : 0;
my $thisSecond = 0,
	$vol = 0,
	$spend = 0;

while(<>){
	chomp;
	my ($microtime, $price, $amount) = split(/\t/);
	my $second = int $microtime/$bucketsize;
	my $average = $vol ? $spend/$vol : 0;
	while ($second > $thisSecond) {
		##print aggregates from last second
		print "$thisSecond\t$spend\t$vol\t$average\n" unless ($thisSecond == 0);
		if ($sparse || $thisSecond == 0){
			$thisSecond = $second;
		}else{
			$thisSecond++;
		}
		$vol = $spend = 0;
	}
	$vol += $amount;
	$spend += $price*$amount;
	print "IN> $_\n" if $DEBUG;
}
