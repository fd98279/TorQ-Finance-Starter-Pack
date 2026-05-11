util:getenv[`KDBAPPCODE],"/common/textutil.q";
system "l ",util;

\d .sravz_finsym


/ Read symbol limit from env/config with safe integer fallback.
getsymbollimit:{[]
  env:getenv`EODWS_SYMBOL_LIMIT;
  if[not ""~env; :.[{`int$x};enlist env;{[e] 45}]];
  :.[value;enlist `symbollimit;{[e] 45}]
  }

/ Resolve symbols CSV path from env/config with default file fallback.
getsymbolsfile:{[]
  env:getenv`EODWS_SYMBOLS_FILE;
  if[not ""~env; :hsym `$env];
  :.[value;enlist `symbolsfile;{
    [e] 
    symbolsfile
    }
    ]
  }

/ Read ticker symbols from CSV (header+rows), normalize to uppercase symbols.
readcsvsymbols:{[f]
  if[not (type f) in -11 10h; :`symbol$()];
  ff:$[-11h=type f;f;hsym `$f];
  lines:@[read0;ff;{[e] ()}];
  if[(count lines)<2; :`symbol$()];
  rows:1_ lines;
  parts:"," vs' rows;
  syms:upper each first each parts;
  syms:ssr[;"\r";""] each syms;
  syms:syms where 0<count each syms;
  `$'syms
  }

/ Build default subscription symbols from CSV, applying configured limit.
defaultsymbols:{[]
  f:getsymbolsfile[];
  .lg.o[`feedws;.sravz_util.msgtxt("symbols file: ";string f)];
  syms:readcsvsymbols f;
  n:getsymbollimit[];
  .lg.o[`feedws;.sravz_util.msgtxt("symbols loaded: ";string count syms;", limit: ";string n)];
  if[(0=count syms) or n<=0;
    .lg.e[`feedws;.sravz_util.msgtxt("Symbol file not found or empty ";string f)];
    '"Symbol file not found or empty: ",string f];
  "," sv string n#syms
  }

/ Initialize global SYMBOLS from env override or computed defaults.
loadsymbols:{[]
  SYMBOLS::{$[""~x;defaultsymbols[];x]}getenv`EODWS_SYMBOLS
  }

/ Return cached symbols, lazily loading once when empty.
getsymbols:{[]
  if[""~SYMBOLS; loadsymbols[]];
  SYMBOLS
  }

SYMBOLS:""

\d .