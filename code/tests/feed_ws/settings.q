/ Load target module with autostart disabled via environment variables.
feedwssrc:getenv[`KDBAPPCODE],"/tick/feed_ws.q";
system "l ",feedwssrc;

/ Test spies for .feedws.onmsg routing assertions.
.ut.subs:`symbol$()
.ut.rawKinds:`symbol$()
.ut.tradeCount:0
.ut.quoteCount:0
.ut.lastRaw:""
.ut.fixture:hsym `$getenv[`KDBAPPCODE],"/tests/feed_ws/symbols_fixture.csv"

.ut.reset:{[]
  .ut.subs::`symbol$();
  .ut.rawKinds::`symbol$();
  .ut.tradeCount::0;
  .ut.quoteCount::0;
  .ut.lastRaw::"";
  }

.ut.mockhandlers:{[]
  .feedws.subscribe:{[kind] .ut.subs,:enlist kind};
  .feedws.publishraw:{[kind;msg;rawtxt] .ut.rawKinds,:enlist kind; .ut.lastRaw::rawtxt};
  .feedws.publishtrade:{[msg] .ut.tradeCount+:1};
  .feedws.publishquote:{[msg] .ut.quoteCount+:1};
  }

.ut.mkwswss:{[]
  ep:.feedws.mkwsconn "wss://example.com";
  `:wss://example.com:443~ep 0
  }

.ut.mkwsws:{[]
  ep:.feedws.mkwsconn "ws://localhost:9000/path";
  `:ws://localhost:9000~ep 0
  }

.ut.mkwsreq:{[]
  ep:.feedws.mkwsconn "ws://localhost:9000/path";
  (2=count ep) and (-11h=type ep 0) and (10h=type ep 1)
  }

.ut.readsymbols:{[]
  syms:.feedws.readcsvsymbols .ut.fixture;
  (0<count syms) and (`AAPL in syms)
  }

.ut.tradefreqtest:{[]
  f:.feedws.gettradefreq[];
  (`long$f)>0
  }

.ut.quotefreqtest:{[]
  f:.feedws.getquotefreq[];
  (`long$f)>0
  }
