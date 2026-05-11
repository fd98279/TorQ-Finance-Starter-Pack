\d .sravz_util

/ Convert any value (including nested lists) to text.
txt:{[x] $[10h=type x;x;0h=type x;raze txt each x;string x]}

/ Join a list of values into one text message for logging.
msgtxt:{[x] raze txt each x}

getenvvar:{[input;default]
  v:$[10h=type input;`$input;-11h=type input;input;`$string input];
  env:@[getenv;v;{[e] ""}];
  if[10h=type env;
    if[""~env; :default];
    :env
    ];
  if[-11h=type env;
    if[env~v; :default];
    s:string env;
    if[""~s; :default];
    :s];
  default
  }

\d .