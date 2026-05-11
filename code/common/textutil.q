\d .sravz_util

/ Convert any value (including nested lists) to text.
txt:{[x] $[10h=type x;x;0h=type x;raze txt each x;string x]}

/ Join a list of values into one text message for logging.
msgtxt:{[x] raze txt each x}

\d .