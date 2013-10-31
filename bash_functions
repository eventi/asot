teststrat(){
	cat testdata.in |
	perl timebucket.pl -s1h |
	perl ema.pl -c4 -i$1 |
	perl ema.pl -c4 -i$2 |
	perl macd.pl -c5,6 |
	perl ema.pl -c7 -i9 |
	perl macd.pl -c7,8 |
	cut -f1,4,7,9 |
	perl strat.pl -m3 -e4 $3 $3 $3 1
}
fitness (){
	teststrat $1 $2 $3 |
	perl fitness.pl -s5 -v2 |
	tail -1 |
	cut -f8
}
