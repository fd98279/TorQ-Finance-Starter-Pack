/ WebSocket feed: subscribes to eodhistoricaldata real-time US equities stream
/ Usage: loaded by TorQ via process.csv, or manually with -load flag
/ Incoming messages are handled by .z.ws and printed to console (stdout)

\d .feedws

WSURL:{$[""~x;"wss://ws.eodhistoricaldata.com/ws/us?api_token=demo";x]}getenv`EODWS_URL
WSQUOTEURL:{$[""~x;"wss://ws.eodhistoricaldata.com/ws/us-quote?api_token=demo";x]}getenv`EODWS_QUOTE_URL
SYMBOLS:{$[""~x;"AMZN,TSLA";x]}getenv`EODWS_SYMBOLS
htrade:0                    / Trade websocket handle
hquote:0                    / Quote websocket handle
tph:0Ni                     / Tickerplant handle
txt:{[x] $[10h=type x;x;0h=type x;raze txt each x;string x]}
msgtxt:{[x] raze txt each x}
wsmsgtxt:{[x] $[10h=type x;x;4h=type x;"c"$x;txt x]}
pick:{[d;cands;def]
  k:key d;
  m:cands inter k;
  $[count m;d first m;def]}

/ build websocket endpoint+HTTP upgrade request from full URL
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

gettph:{[]
  if[not null tph; :tph];
  tph::.[{.servers.gethandlebytype[`segmentedtickerplant;`any]};();{[e] 0Ni}];
  if[null tph;
    tph::@[hopen;`:localhost:6000:admin:admin;{[e]
      .lg.w[`feedws;msgtxt("tickerplant handle unavailable: ";e)];
      0Ni
    }]];
  if[not null tph;
    .lg.o[`feedws;msgtxt("tickerplant handle=",tph)]];
  tph}

publishtrade:{[msg]
  th:gettph[];
  if[null th; :()];
  k:key msg;
  px:msg`p;
  sz:`int$$[`v in k;msg`v;0];
  stop:$[`dp in k;msg`dp;0b];
  ex:$[`ms in k;first upper txt msg`ms;" "];
  row:(enlist `$txt msg`s; enlist px; enlist sz; enlist stop; enlist " "; enlist ex; enlist `unknown);
  neg[th] (".u.upd";`trade;row)}

publishquote:{[msg]
  th:gettph[];
  if[null th; :()];
  sym:`$txt pick[msg;`s`symbol;`];
  if[sym~`; :()];
  px:pick[msg;`p`price`last`lp;0n];
  bid:pick[msg;`b`bid`bp`bid_price;px];
  ask:pick[msg;`a`ask`ap`ask_price;px];
  vol:pick[msg;`v`size`last_size`volume;0];
  bsize:`long$pick[msg;`bs`bsize`bid_size`bv;vol];
  asize:`long$pick[msg;`as`asize`ask_size`av;vol];
  mode:$[0<count ms:txt pick[msg;`ms`session`mode;""];first upper ms;" "];
  ex:$[0<count exs:txt pick[msg;`ex`exchange`mic;""];first upper exs;mode];
  src:`$txt pick[msg;`src`source;`eod];
  row:(enlist sym; enlist bid; enlist ask; enlist bsize; enlist asize; enlist mode; enlist ex; enlist src);
  neg[th] (".u.upd";`quote;row)}

kindbyhandle:{[wh]
  $[wh~htrade;`trade;
    wh~hquote;`quote;
    `unknown]}

/ handle each incoming WebSocket message
onmsg:{[wh;x]
  .[{[wh;x]
    kind:kindbyhandle wh;
    msgtxt0:wsmsgtxt x;
    msg:{.[{.j.k x};enlist x;{[e] .lg.w[`feedws;msgtxt("failed to parse message: ";e;", raw=";msgtxt0)]; ()!()}]}[msgtxt0];
    if[0=count msg; :()];
    / authorisation / status messages
    if[`status_code in key msg;
      .lg.o[`feedws;msgtxt(string kind;" server: ";msg`status_code;" ";msg`message)];
      / send subscription after authorisation
      if[200=msg`status_code; subscribe kind];
      :()];
    / Route trade and quote ticks based on websocket handle.
    if[`s in key msg;
      $[kind~`trade;publishtrade[msg];
        kind~`quote;publishquote[msg];
        .lg.w[`feedws;msgtxt("dropping tick from unknown handle=";wh)]]];
    };
    (wh;x);
    {[e] .lg.e[`feedws;msgtxt("onmsg failed: ";e)]}
  ];
  }

/ send subscription request
subscribe:{[kind]
  req:.j.j `action`symbols!("subscribe";SYMBOLS);
  .lg.o[`feedws;msgtxt(string kind;" subscribing: ";req)];
  $[kind~`trade;neg[htrade] req;
    kind~`quote;neg[hquote] req;
    .lg.w[`feedws;msgtxt("unknown subscription kind=";kind)]];}

/ connect to the WebSocket endpoint
connectone:{[kind;url]
  .lg.o[`feedws;msgtxt(string kind;" connecting to ";url)];
  c:@[mkwsconn;url;{[e] .lg.e[`feedws;msgtxt(string kind;" invalid url: ";url;", err=";e)]; ()}];
  if[0=count c; :()];
  r:.[{[ep;req] ep req};c;{[e] (`err;txt e)}];
  if[0h~type r;
    if[`err~first r;
      .lg.e[`feedws;msgtxt(string kind;" connection failed: ";last r;", url=";url)];
      :()]];
  if[2<>count r;
    .lg.e[`feedws;msgtxt(string kind;" connection failed: unexpected handshake response, url=";url)];
    :()];
  if[0Ni=r 0;
    .lg.e[`feedws;msgtxt(string kind;" handshake rejected: ";r 1)];
    :()];
  $[kind~`trade;htrade::r 0;hquote::r 0];
  .lg.o[`feedws;msgtxt(string kind;" handshake response: ";r 1)];
  .lg.o[`feedws;msgtxt(string kind;" connected, handle=";r 0)];}

connect:{
  connectone[`trade;WSURL];
  connectone[`quote;WSQUOTEURL];}

\d .

/ override .z.ws to route messages to our handler
.z.ws:{.feedws.onmsg[.z.w;x]}

/ connect on load
.feedws.connect[]
