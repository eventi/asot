#!/usr/bin/env perl
use Getopt::Std;
$|=1;

my %options={};
getopts("ps:dz",\%options);

my $DEBUG = defined $options{d} ? 1 : 0;
my $bucketsize;
if (defined $options{s}) {
	my $size = $options{s};
	my $unit = lc chop $size;
	print "size:$size\tunit:$unit\n" if $DEBUG;
	if($unit eq 's'){
		$bucketsize = $size*1000*1000;
	}elsif($unit eq 'm'){
		$bucketsize = $size*60*1000*1000;
	}elsif($unit eq 'h'){
		$bucketsize = $size*60*60*1000*1000;
	}else{
		$bucketsize = $size*10+$unit;
	};
}else{
	$bucketsize = 1000*1000;
}
print "bucketsize: $bucketsize\n" if $DEBUG;
#TODO - support [0-9]+[smhdwy]
my $sparse = defined $options{z} ? 1 : 0;
my $passthru = defined $options{p} ? 1 : 0;
my $thisPeriod = 0,
	$vol = 0,
	$spend = 0;

while(<>){
	if(/^#/){
		print $_ if $passthru;
	}else{
		print "#" . $_ if $passthru;
		chomp;
		my ($microtime, $price, $amount) = split(/\t/);
		my $period = int $microtime/$bucketsize;
		my $average = $vol ? $spend/$vol : 0;
		print "period: $period\tthisPeriod:$thisPeriod\n" if $DEBUG;
		while ($period > $thisPeriod) {
			##print aggregates from last period
			print "$thisPeriod\t$spend\t$vol\t$average\n" unless ($thisPeriod == 0);
			if ($sparse || $thisPeriod == 0){
				$thisPeriod = $period;
			}else{
				$thisPeriod++;
			}
			$vol = $spend = 0;
		}
		$vol += $amount;
		$spend += $price*$amount;
	}
}
