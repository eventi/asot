#!/usr/bin/env perl
use Data::Dumper;
use Getopt::Std;
my %options={};
getopts("de:",\%options);

# -e4:10,20

my $DEBUG = defined $options{d} ? 1 : 0;
my $emastr = $options{e};
print Dumper("emastr:",$emastr);

my ($col,$istr) = split(/:/,$emastr);
my (@emas) = split(/,/,$istr);

print Dumper("emas:",@emas);
exit;

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
