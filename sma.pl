#!/usr/bin/env perl
use Data::Dumper;
use Getopt::Std;
$| = 1;

my %options={};
getopts("pdc:",\%options);

# -c4

my $DEBUG = defined $options{d} ? 1 : 0;
my $passthru = defined $options{p} ? 1 : 0;
my $col = $options{c};

print "col:$col\n" if $DEBUG;

my @rows = ();
while(<>){
	if(/^#/){
		print $_ if $passthru;
	}else{
		print "#" . $_ if $passthru;
		chomp;
		push(@rows,$_);
		my @cols = split(/\t/);
		if (scalar(@rows)>10){
			print "SHIFTING" if $DEBUG;
			shift @rows;
		}
		my $tot = 0;
		my $sma = 0;
		for $r (@rows) {
			print "ROW:[$r]\n" if $DEBUG;
			my @c = split(/\t/,$r);
			print "\@c" . Dumper(@c) . "\n" if $DEBUG;
			$tot += $c[$col-1];
			$sma = $tot/scalar(@rows);
			print "sma:$sma\n" if $DEBUG;
		}
		print "$_\t$sma\n";
	}
}
