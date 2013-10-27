use Finance::MtGox;
use Data::Dumper;
use MtGoxConfig;

print "APIKEY: ".APIKEY."\n" if $DEBUG;
print "APISECRET: ".APISECRET."\n" if $DEBUG;

my $mtgox = Finance::MtGox->new({
  key     => APIKEY,
  secret  => APISECRET,
});
# 'key' and 'secret' authentication works too

# unauthenticated API calls
#my $depth = $mtgox->call('getDepth');
#print "Depth: " . Dumper($depth);

# authenticated API calls
my $funds = $mtgox->call_auth('getFunds');
print "Funds: " . Dumper($funds);

# convenience methods built on the core API
my $rate = $mtgox->clearing_rate( 'asks', 0.001, 'BTC' );
print "rate 1.001btc: $rate\n";

my $info = $mtgox->call_auth('BTCUSD/money/order/add',{
	type=>'ask',
	amount_int=>100
});
print "HERE\n";
print Dumper($info);
