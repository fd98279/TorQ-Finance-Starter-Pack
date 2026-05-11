/ Load target module with autostart disabled via environment variables.
finsym:getenv[`KDBAPPCODE],"/finsym/finsym.q";
system "l ",finsym;

/ Test spies for .feedws.onmsg routing assertions.
.ut.fixture:hsym `$getenv[`TORQAPPHOME],"/tests/finsym/symbols_fixture.csv"

.ut.readsymbols:{[]
  syms:.sravz_finsym.readcsvsymbols .ut.fixture;
  (0<count syms) and (`AAPL in syms)
  }

.ut.getsymbollimit:{[]
  limit:.sravz_finsym.getsymbollimit[];
  (`long$limit)=45 / default limit from settings in feed.q
  }

.ut.getsymbolsfile:{[]
  f:.sravz_finsym.getsymbolsfile[];
  -11h=type f
  }

.ut.defaultsymbols:{[]
  s:.sravz_finsym.defaultsymbols[];
  (10h=type s) and 3=count s
  }

/.ut.readcsvsymbols:{[]
/  syms:.sravz_finsym.readcsvsymbols .ut.fixture;
/  (0<count syms) and (`AAPL in syms)
/}


// .ut.getsymbollimit_with_env:{[]
//   / setenv is not available in q; emulate override by temporarily setting config variable.
//   oldcfg:.[value;enlist `.sravz_finsym.symbollimit;{[e] 45}];
//   limit:@[{[]
//       .sravz_finsym.symbollimit::30;
//       `long$.sravz_finsym.getsymbollimit[]
//     };();{[e] 0N}];
//   .sravz_finsym.symbollimit::oldcfg;
//   30=limit
//   }  