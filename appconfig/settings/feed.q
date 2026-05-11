// Bespoke Feed config : Finance Starter Pack

\d .servers	
enabled:1b						
CONNECTIONS:enlist `segmentedtickerplant		// Feedhandler connects to the tickerplant
HOPENTIMEOUT:30000

\d .sravz_finsym
symbolsfile:hsym `$getenv[`KDBAPPCODE],"/finsym/us_index_tickers_ndx_sp500.csv"
symbollimit:45

\d .feedws
tradefreq:10        / minimum seconds between trade publishes per symbol
quotefreq:10        / minimum seconds between quote publishes per symbol
