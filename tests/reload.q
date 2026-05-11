/ Reload and run tests for current process test path(s).
t:.proc.params`test;
dirs:$[10h=type t;enlist t;11h=type t;string each t;t];

// Reload per-test settings so helper changes are picked up in debug sessions.
{[d] @[system;enlist "l ",d,"/settings.q";::]} each dirs;

KUT:0#KUT
KUTR:0#KUTR

KUltd each hsym `$'dirs;
KUrt[];
show select from KUTR where not ok;