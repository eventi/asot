#!/usr/bin/env perl
use LWP::Simple;
use Data::Dumper;
use JSON;
use Getopt::Std;
use Time::HiRes qw ( setitimer ITIMER_REAL time );
$| = 1;

use constant STARTEPOCH => 1382140800; #2013-10-19:00:00.000Z
use constant WAITTIME => 1;

my %options={};
getopts("s:d",\%options);

my $DEBUG = defined $options{d} ? 1 : 0;
my $since = defined $options{s} ? $options{s} : STARTEPOCH * 1000 * 1000;

$SIG{ALRM} = sub {
	print "IN VTALRM: since=$since\n" if $DEBUG;
	my $json = get("http://data.mtgox.com/api/2/BTCUSD/money/trades/fetch?since=$since");
	my @trades = @{(from_json($json))->{data}};

	foreach $trade (@trades) {
		my $microtime = $trade->{tid};
		if ( $microtime > $since ){
			$since = $microtime;
		}
		if($trade->{primary} == 'Y'){
			print $microtime . "\t";
			print $trade->{price} . "\t";
			print $trade->{amount} . "\n";
		}
	}
};

setitimer(ITIMER_REAL, 1,WAITTIME);

while (1) { };
exit;



use LWP::UserAgent;
use DateTime;

## CONSTANTS ##
#use constant STARTEPOCH => 1356998400; #2013-01-01T00:00:00.000Z
#use constant STEPTIME => "6e4"; #60000ms = one minute
use constant STEPTIME => "36e5"; #3600000ms =  one hour

my $pushover = 0;

## TESTS ##
my $strategy = {
	0 => { #S0 enter on 3rd positive macd, exit on first negative macd
		usd => 100,
		btc => 0,
		m1  => 0,
		m2  => 0,
		st  => \&testS0
	},
	1 => {
		usd => 100,
		btc => 0,
		st  => \&testS1
	},
};

sub testS0 {
	my ($tick,$strat)  = @_;
	my $macd    = $tick->{data}->{ema}->{macd10_20};
	my $average = $tick->{data}->{average};
	my $thisTime= $tick->{time};
	if($macd>0){
		if($strat->{m2} && $strat->{usd}>0){
			#BUY ALL
			$strat->{btc} = $strat->{usd}/$average;
			$strat->{usd} = 0;
			print "0 BUY: $strat->{btc}\@$average\n";
			if($pushover) {
				pushoverAlert("BUY!! macd:$macd \$$average");
			}
			reportStrategies($thisTime,$average);
		}else{
			if($strat->{m1}){
				$strat->{m2}=1;
			}else{
				$strat->{m1}=1;
			}
		}
	}else{
		#SELL ALL
		if($strat->{btc}>0){
			print "0 SELL: $strat->{btc}\@$average\n";
			$strat->{usd} = $strat->{btc}*$average;
			$strat->{btc} = 0;
			reportStrategies($thisTime,$average);
			if($pushover) {
				pushoverAlert("SELL!! macd:$macd \$$average");
			}
		}
		$strat->{m2}=$strat->{m1}=0;
	}
}

sub testS1 {
	my ($tick,$strat)  = @_;
	my $average = $tick->{data}->{average};
	my $thisTime= $tick->{time};
	if($strat->{usd}>0){
		$strat->{btc} = $strat->{usd}/$average;
		$strat->{usd} = 0;
		print "1 BUY: $strat->{btc}\@$average\n";
		reportStrategies($thisTime,$average);
	}
}

sub testStrategies {
	my ($tick)  = @_;
	$strategy->{0}->{st}->($tick,$strategy->{0});
	$strategy->{1}->{st}->($tick,$strategy->{1});
}

sub reportStrategies {
		my ($time,$avg)  = @_;
		foreach $s (0,1) {
			my $usd = $strategy->{$s}->{usd};
			my $btc = $strategy->{$s}->{btc};
			my $val = $usd + $btc * $avg;
			#print "$s $time\tusd:$usd\tbtc:$btc\tval:$val\n";
			print "$time val $s: \$$val (usd:$usd\tbtc:$btc)\n";
		}
}

my $ua = LWP::UserAgent->new();

$host = "localhost:1081";
$path = "/1.0";

sub getMetrics {
	my ($exp,$start,$stop) = @_;
	my $step = STEPTIME;
	my $url = "http://$host$path/metric?expression=$exp&step=$step"
		."&start=" . $start # DateTime->from_epoch(epoch=>$start)
		."&stop="  . $stop;  # DateTime->from_epoch(epoch=>$stop);
	my $content = get($url);
	die "Can't get URL($url)" unless defined $content;
	return @{from_json($content)};
}

sub getEvents {
	my ($exp,$start,$stop) = @_;
	my $step = STEPTIME;
	my $url = "http://$host$path/event?expression=$exp&step=$step"
		."&start=" . $start # DateTime->from_epoch(epoch=>$start)
		."&stop="  . $stop;  # DateTime->from_epoch(epoch=>$stop);
	my $content = get($url);
	die "Can't get URL($url)" unless defined $content;
	return @{from_json($content)};
}

sub getSMA {
	my ($intervals,$stop) = @_;
	my $start = $stop->clone();
##TODO
## Create DateTime duration relevent to STEPTIME
	$start->add(hours=>-$intervals);
	#print "Start: $start\n";
	#print "Stop: $stop\n";
	my @vols   = getMetrics("sum(trade(amount))",$start,$stop);
	#print "@vols:\n" . Dumper(@vols);
	my @spends = getMetrics("sum(trade(amount*price))",$start,$stop);
	my $vol = 0;
	my $spend = 0;
	foreach $v (@vols) { $vol += $v->{value}*1; }
	foreach $s (@spends) { $spend += $s->{value}*1; }
	my $sma = $vol ? $spend / $vol : 0;
	if ($sma > 300) {
		print "vol: $vol\tspend: $spend\n";
		print "@vols:\n" . Dumper(@vols);
		print "@spends:\n" . Dumper(@spends);
		exit;
	}
	return $sma;
}

sub getEMA {
	my ($intervals,$price,$stop) = @_;
	my $EMAlast;
	my $prior = $stop->clone();
##TODO
## Create DateTime duration relevent to STEPTIME
	$prior->add(hours=>-1);
	my @res = getEvent("tick(ema.n$intervals)",$prior);
	if (@res) {
		$EMAlast = $res[0]->{data}->{ema}->{"n$intervals"};
	}else{
		@res = getEvent("tick(sma.n$intervals)",$prior);
		if(@res){
			$EMAlast = $res[0]->{data}->{sma}->{"n$intervals"};
		}else{
			$EMAlast = getSMA($intervals,$prior);
		}
	}
	my $k = 2/($intervals+1);
	my $ema = $price * $k + $EMAlast * (1-$k);
	return $ema;
}

sub getMetric {
	my ($exp,$start) = @_;
	my $stop = $start->clone();
##TODO
## Create DateTime duration relevent to STEPTIME
	$stop->add(hours=>1);
	return getMetrics($exp,$start,$stop);
}
	
sub getEvent {
	my ($exp,$start) = @_;
	my $stop = $start->clone();
##TODO
## Create DateTime duration relevent to STEPTIME
	$stop->add(hours=>1);
	return getEvents($exp,$start,$stop);
}

my $thisTime = DateTime->from_epoch(epoch => STARTEPOCH);
my $lastavg = 0;

while (DateTime->compare($thisTime,DateTime->now) < 0) {
	my $tick = makeTick($thisTime);

	my $json = to_json($tick,{allow_blessed=>1});
	$json = "[$json]";

	my $req = HTTP::Request->new( 'POST', "http://localhost:1080/1.0/event/put" );
	$req->header('Content-Type'=> 'application/json');
	$req->content($json);

	my $res = $ua->request($req);
	if ($res->is_success) {
		print $json . "\n";
	}else{
		print $res->decoded_content;
		die $res->status_line;
	}

	testStrategies($tick);

	if (STEPTIME == "36e5") {
		$thisTime->add(hours=>1);
	}elsif (STEPTIME == "6e4") {
		$thisTime->add(minutes=>1);
	}else{
		die "Can't increment";
	}
}

my $dont_exit = 0;

$pushover = 1;
$DEBUG=1;
print "Monitoring since " . DateTime->from_epoch(epoch=>time), "\n";
$SIG{VTALRM} = sub {
	print "thisTime: $thisTime\tnow: ". DateTime->now ."\n";
	if (DateTime->compare($thisTime,DateTime->now) < 0) {
		my $lastTime =  $thisTime->clone();
		$lastTime->add(hours=>-1);
		my $tick = makeTick($lastTime);

		my $json = to_json($tick,{allow_blessed=>1});
		$json = "[$json]";

		print $json . "\n" if $DEBUG;

		my $req = HTTP::Request->new( 'POST', "http://localhost:1080/1.0/event/put" );
		$req->header('Content-Type'=> 'application/json');
		$req->content($json);

		my $res = $ua->request($req);
		if ($res->is_success) {
			print $json . "\n";
		}else{
			print $res->decoded_content;
			die $res->status_line;
		}

		testStrategies($tick);

		if (STEPTIME == "36e5") {
			$thisTime->add(hours=>1);
		}elsif (STEPTIME == "6e4") {
			$thisTime->add(minutes=>1);
		}else{
			die "Can't increment";
		}
	}
	print $dont_exit++ . "\n";

};
setitimer(ITIMER_REAL, 1,10);

while($dont_exit < 10000){ }


sub makeTick {
	my ($time) = @_;
	print "makeTick($time)\n" if $DEBUG;
	my $volume = (getMetric("sum(trade(amount))",$time))[0]->{value};
	my $spend  = (getMetric("sum(trade(amount*price))",$time))[0]->{value};
	my $average  = $volume > 0 ? $spend / $volume : $lastavg;
	$lastavg = $average;
	my $min    = $volume ? getMetric("min(trade(price))",$time) : $average;
	my $max    = $volume ? getMetric("max(trade(price))",$time) : $average;
	my $ema10  = getEMA(10,$average,$time);
	my $ema20  = getEMA(20,$average,$time);
	my $macd   = $ema10 - $ema20;

	my $tick = {
		"type" => "tick",
		"time" => $time . "",
		"id"   => $time . "",
		"data" => {
			"volume"  => $volume,
			"spend"   => $spend,
			"average" => $average,
			"min"     => $min,
			"max"     => $max,
			"ema"	  => {
				"n10" => $ema10,
				"n20" => $ema20,
				"macd10_20" => $macd,
			},
		}
	};
	pushoverAlert("macd:$macd \$$average") if $pushover;
	return $tick;
}

sub pushoverAlert {
	my ($message) = @_;

	LWP::UserAgent->new()->post(
		"https://api.pushover.net/1/messages.json",
		[
			"token"   => "aBHhuTu1VuBkXrMVfLyMhQRcEsQYbD",
			"user"    => "tEC15CckpassLKO28jwOS1Cm0483Cs",
			"message" => $message,
			"sound"   => "cashregister",
		]
	);
};
