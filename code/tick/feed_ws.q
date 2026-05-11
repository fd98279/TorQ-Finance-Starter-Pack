/ WebSocket feed: subscribes to eodhistoricaldata real-time US equities stream
/ Usage: loaded by TorQ via process.csv, or manually with -load flag
/ Incoming messages are handled by .z.ws and printed to console (stdout)

util:getenv[`KDBAPPCODE],"/common/util.q";
system "l ",util;

\d .feedws

WSURL:{$[""~x;"wss://ws.eodhistoricaldata.com/ws/us?api_token=demo";x]}getenv`EODWS_URL
WSQUOTEURL:{$[""~x;"wss://ws.eodhistoricaldata.com/ws/us-quote?api_token=demo";x]}getenv`EODWS_QUOTE_URL
htrade:0                    / Trade websocket handle
hquote:0                    / Quote websocket handle
tph:0Ni                     / Tickerplant handle
/ Convert websocket payload to text (string, bytes, or general value).
wsmsgtxt:{[x] $[10h=type x;x;4h=type x;"c"$x;.sravz_util.txt x]}
/ Return first matching key from candidate list, or default if none exist.
pick:{[d;cands;def]
  k:key d;
  m:cands inter k;
  $[count m;d first m;def]}

/ Per-symbol throttle state: last publish timestamp per sym
lasttrade:(`$())!`timestamp$()
lastquote:(`$())!`timestamp$()

/ Per-symbol last-known bid/ask cache (for partial quote updates)
lastbid:(`$())!`float$()
lastask:(`$())!`float$()

/ Read trade publish interval in seconds from env/config with fallback.
gettradefreq:{[]
  env:getenv`EODWS_TRADE_FREQ;
  if[not ""~env; :.[{`long$x};enlist env;{[e] 10}]];
  v:.[value;enlist `.feedws.tradefreq;{[e] 10}];
  :$[7h=type v;v;
     6h=type v;`long$v;
     9h=type v;`long$v;
     10h=type v;.[{`long$x};enlist v;{[e] 10}];
     10]
  }

/ Read quote publish interval in seconds from env/config with fallback.
getquotefreq:{[]
  env:getenv`EODWS_QUOTE_FREQ;
  if[not ""~env; :.[{`long$x};enlist env;{[e] 10}]];
  v:.[value;enlist `.feedws.quotefreq;{[e] 10}];
  :$[7h=type v;v;
     6h=type v;`long$v;
     9h=type v;`long$v;
     10h=type v;.[{`long$x};enlist v;{[e] 10}];
     10]
  }

/ throttle intervals as timespans, computed once at load
TRADEFREQ:`timespan$`long$1e9*gettradefreq[]
QUOTEFREQ:`timespan$`long$1e9*getquotefreq[]

/ Build websocket endpoint and HTTP upgrade request from full URL.
mkwsconn:{[url]
  pre:$[("wss://"~6#url);6;("ws://"~5#url);5;0];
  if[0=pre; '"invalid websocket url"];
  rest:pre _ url;
  parts:"/" vs rest;
  if[0=count parts; '"invalid websocket url"];
  host:first parts;
  hostport:$[":" in host;host;host,$[6=pre;":443";":80"]];
  path:$[1<count parts;"/","/" sv 1_ parts;"/"];
  (`$ raze (":"; pre#url; hostport);"GET ",path," HTTP/1.1\r\nHost: ",hostport,"\r\n\r\n")
 }

/ parse a single JSON message from the server
/ returns a dict or empty dict on parse failure
// parse:

/ Return cached tickerplant handle, attempting discovery/open on demand.
gettph:{[]
  if[not null tph; :tph];
  tph::.[{.servers.gethandlebytype[`segmentedtickerplant;`any]};();{[e] 0Ni}];
  if[null tph;
    tph::@[hopen;`:localhost:6000:admin:admin;{[e]
      .lg.w[`feedws;.sravz_util.msgtxt("tickerplant handle unavailable: ";e)];
      0Ni
    }]];
  if[not null tph;
    .lg.o[`feedws;.sravz_util.msgtxt("tickerplant handle=",tph)]];
  tph}

/ Publish normalized trade row to tickerplant with per-symbol throttling.
publishtrade:{[msg]
  th:gettph[];
  if[null th; :()];
  k:key msg;
  sym:`$.sravz_util.txt msg`s;
  now:.z.p;
  lastseen:lasttrade[sym];
  if[(not null lastseen) and (now-lastseen)<TRADEFREQ; :()];
  lasttrade[sym]::now;
  px:msg`p;
  sz:`int$$[`v in k;msg`v;0];
  stop:$[`dp in k;msg`dp;0b];
  ex:$[`ms in k;first upper .sravz_util.txt msg`ms;" "];
  row:(enlist sym; enlist px; enlist sz; enlist stop; enlist " "; enlist ex; enlist `unknown);
  neg[th] (".u.upd";`trade;row)}

/ Publish normalized quote row to tickerplant with per-symbol throttling.
publishquote:{[msg]
  th:gettph[];
  if[null th; :()];
  sym:`$.sravz_util.txt pick[msg;`s`symbol;`];
  if[sym~`; :()];
  now:.z.p;
  lastseen:lastquote[sym];
  if[(not null lastseen) and (now-lastseen)<QUOTEFREQ; :();]
  lastquote[sym]::now;
  px:pick[msg;`p`price`last`lp;0n];
  bid:pick[msg;`b`bid`bp`bid_price;px];
  ask:pick[msg;`a`ask`ap`ask_price;px];
  / fall back to last-known prices on partial updates (sizes-only ticks)
  bid:$[null bid;@[lastbid;sym;0n];bid];
  ask:$[null ask;@[lastask;sym;0n];ask];
  lastbid[sym]::bid;
  lastask[sym]::ask;
  vol:pick[msg;`v`size`last_size`volume;0];
  bsize:`long$pick[msg;`bs`bsize`bid_size`bv;vol];
  asize:`long$pick[msg;`as`asize`ask_size`av;vol];
  mode:$[0<count ms:.sravz_util.txt pick[msg;`ms`session`mode;""];first upper ms;" "];
  ex:$[0<count exs:.sravz_util.txt pick[msg;`ex`exchange`mic;""];first upper exs;mode];
  src:`$.sravz_util.txt pick[msg;`src`source;`eod];
  row:(enlist sym; enlist bid; enlist ask; enlist bsize; enlist asize; enlist mode; enlist ex; enlist src);
  neg[th] (".u.upd";`quote;row)}

/ Publish raw message envelope to tickerplant for audit/debug streams.
publishraw:{[kind;msg;rawtxt]
  th:gettph[];
  if[null th; :()];
  sym:`$.sravz_util.txt pick[msg;`s`symbol;`];
  if[sym~`; :()];
  px:`float$pick[msg;`p`price`last`lp;0n];
  bid:`float$pick[msg;`b`bid`bp`bid_price;px];
  ask:`float$pick[msg;`a`ask`ap`ask_price;px];
  sz:`long$pick[msg;`v`size`last_size`volume;0];
  bsize:`long$pick[msg;`bs`bsize`bid_size`bv;sz];
  asize:`long$pick[msg;`as`asize`ask_size`av;sz];
  providerts:$[`t in key msg;"p"$1000000*`long$msg`t;0Np];
  src:`$.sravz_util.txt pick[msg;`src`source;`eod];
  row:(enlist providerts; enlist sym; enlist kind; enlist px; enlist bid; enlist ask; enlist sz; enlist bsize; enlist asize; enlist rawtxt; enlist src);
  neg[th] (".u.upd";`eodwsraw;row)}

/ Classify websocket handle as trade, quote, or unknown stream kind.
kindbyhandle:{[wh]
  $[wh~htrade;`trade;
    wh~hquote;`quote;
    `unknown]}

/ Handle each incoming websocket message: parse, log, route, and publish.
onmsg:{[wh;x]
  .[{[wh;x]
    kind:kindbyhandle wh;
    msgtxt0:wsmsgtxt x;
    msg:{.[{.j.k x};enlist x;{[e] .lg.w[`feedws;.sravz_util.msgtxt("failed to parse message: ";e;", raw=";msgtxt0)]; ()!()}]}[msgtxt0];
    if[0=count msg; :()];
    / authorisation / status messages
    if[`status_code in key msg;
      .lg.o[`feedws;.sravz_util.msgtxt(string kind;" server: ";msg`status_code;" ";msg`message)];
      / send subscription after authorisation
      if[200=msg`status_code; subscribe kind];
      :()];
    / Route trade and quote ticks based on websocket handle.
    if[`s in key msg;
      publishraw[kind;msg;msgtxt0];
      $[kind~`trade;publishtrade[msg];
        kind~`quote;publishquote[msg];
        .lg.w[`feedws;.sravz_util.msgtxt("dropping tick from unknown handle=";wh)]]];
    };
    (wh;x);
    {[e] .lg.e[`feedws;.sravz_util.msgtxt("onmsg failed: ";e)]}
  ];
  }

/ Send subscription request for the given stream kind.
subscribe:{[kind]
  req:.j.j `action`symbols!("subscribe";.sravz_finsym.getsymbols[]);
  .lg.o[`feedws;.sravz_util.msgtxt(string kind;" subscribing: ";req)];
  $[kind~`trade;neg[htrade] req;
    kind~`quote;neg[hquote] req;
    .lg.w[`feedws;.sravz_util.msgtxt("unknown subscription kind=";kind)]];}

/ Connect one websocket stream and validate handshake response.
connectone:{[kind;url]
  .lg.o[`feedws;.sravz_util.msgtxt(string kind;" connecting to ";url)];
  c:@[mkwsconn;url;{[e] .lg.e[`feedws;.sravz_util.msgtxt(string kind;" invalid url: ";url;", err=";e)]; ()}];
  if[0=count c; :()];
  r:.[{[ep;req] ep req};c;{[e] (`err;.sravz_util.txt e)}];
  if[0h~type r;
    if[`err~first r;
      .lg.e[`feedws;.sravz_util.msgtxt(string kind;" connection failed: ";last r;", url=";url)];
      :()]];
  if[2<>count r;
    .lg.e[`feedws;.sravz_util.msgtxt(string kind;" connection failed: unexpected handshake response, url=";url)];
    :()];
  if[0Ni=r 0;
    .lg.e[`feedws;.sravz_util.msgtxt(string kind;" handshake rejected: ";r 1)];
    :()];
  $[kind~`trade;htrade::r 0;hquote::r 0];
  .lg.o[`feedws;.sravz_util.msgtxt(string kind;" handshake response: ";r 1)];
  .lg.o[`feedws;.sravz_util.msgtxt(string kind;" connected, handle=";r 0)];}

/ Connect both trade and quote websocket streams.
connect:{
  connectone[`trade;WSURL];
  connectone[`quote;WSQUOTEURL];}

/ Decide whether module should autostart connections on load.
autostart:{[]
  (""~getenv`FEEDWS_NOSTART) and ""~getenv`FEEDWS_NOCONNECT
  }

\d .

/ override .z.ws to route messages to our handler
.z.ws:{.feedws.onmsg[.z.w;x]}

/ connect on load
if[.feedws.autostart[];
  .sravz_finsym.loadsymbols[];
  .feedws.connect[]]
