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
my ( $btcs, $usds ) = $mtgox->balances;
print "btc: $btcs\tusd: $usds\n";
my $rate = $mtgox->clearing_rate( 'asks', 200, 'BTC' );
print "rate ASK 200BTC: $rate\n";
$rate    = $mtgox->clearing_rate( 'bids',  42, 'USD' );
print "rate BID 42USD: $rate\n";
