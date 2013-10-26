#!/usr/bin/env perl
use Data::Dumper;
use Getopt::Std;
$| = 1;

my %options={};
getopts("pdc:",\%options);

# -c4,5

my $DEBUG = defined $options{d} ? 1 : 0;
my $passthru = defined $options{p} ? 1 : 0;
my ($short,$long) = split(/,/,$options{c});

print "short:$short\tlong:$long\n" if $DEBUG;

while(<>){
	print "DEBUG!!\n" if $DEBUG;
	if(/^#/){
		print $_ if $passthru;
	}else{
		print "#" . $_ if $passthru;
		chomp;
		my @c = split(/\t/);
		print "short: " . $c[$short-1] ."\t". "long:" . $c[$long-1] . "\n" if $DEBUG;
		my $macd = $c[$short-1] - $c[$long-1];
		print "$_\t$macd\n";
	}
}
