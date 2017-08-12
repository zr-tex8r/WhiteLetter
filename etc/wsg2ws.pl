#
# wsg2ws.pl
#
use strict;
sub main {
  local ($_, $/);
  binmode(STDOUT);
  init_sys();
  $_ = <>; 
  print(whitify(compile(preprocess($_))))
}

#------ subprocedures of compiler

my (%operat);
my $op_gen = <<'END';
PSH*  SS
DUP   SLS
CPY*  STS
SWP   SLT
POP   SLL
SLD*  STL
ADD   TSSS
SUB   TSST
MUL   TSSL
DIV   TSTS
MOD   TSTT
STO   TTS
LOD   TTT
LBL:  LSS
CAL:  LST
JMP:  LSL
JZR:  LTS
JNG:  LTT
RET   LTL
EXT   LLL
OUC  TLSS
OUN  TLST
INC  TLTS
INN  TLTT
END
sub init_sys {
  foreach (split(m/\n/, $op_gen)) {
    (m/^(\w+)([\:\*])?\s+(\w+)/) or die "Oops-1";
    $operat{$1} = [ $2, $3 ];
  }
}

use constant { MAXREP => 64 };
sub preprocess {
  my ($txt) = @_; my ($dir, $arg, $k, %macro);
  $txt =~ s/\#.*$//gm;
  while ($txt =~ m/^\s*\@(\w+)\s+(.*?)\s*$/gm) {
    ($dir, $arg) = ($1, $2);
    if ($dir eq 'define') {
      if ($arg =~ m/^(\w+)\s+(.*)$/) {
        $macro{$1} = $2;
      } else { die "syntax error in directive $dir"; }
    } else { die "unknown directive $dir found"; }
  }
  $txt =~ s/^\s*\@.*$//gm;
  #
  for ($k = 0; $k < MAXREP; $k++) {
    $txt =~ s[\$(\w+)|\$\{(\w+)\}]{
      (exists $macro{$+}) or die "unknown macro $+ found";
      $macro{$+}
    }ge or last;
  }
  ($k < MAXREP) or die "macro too deeply nested";
  #
  return $txt;
}

sub compile {
  my ($txt) = @_;
  my ($t, $e, $ope, $arg, $aty, $img, @toks, @cnks);
  @toks = split(m/\s+/, $txt);
  foreach $t (@toks) {
    if ($t eq '') { next; }
    elsif ($t =~ m/^\"(-?\w+)$/) { ($ope, $arg) = ("PSH", hex($1)); }
    elsif ($t =~ m/^\`(\w)$/) { ($ope, $arg) = ("PSH", ord($1)); }
    elsif ($t =~ m/^-?\d+$/) { ($ope, $arg) = ("PSH", $t); }
    elsif ($t =~ m/^\:(\d+)$/) { ($ope, $arg) = ("LBL", $1); }
    elsif ($t =~ m/^([A-Z]+)(\d+)?$/) { ($ope, $arg) = ($1, $2); }
    else { die "Invalid token $t found"; }
    (defined($e = $operat{$ope}))
      or die "Invalid operator $ope found";
    ($aty, $img) = @$e;
    (($aty eq '') == ($arg eq ''))
      or die "Illegal argument type $t found";
    push(@cnks, $img);
    if ($aty eq '*') { push(@cnks, image_num($arg)); }
    elsif ($aty eq ':') { push(@cnks, image_label($arg)); }
  }
  return join('', @cnks);
}

sub image_num {
  my ($n) = @_; my ($s);
  ($s, $n) = ($n >= 0) ? ('S', $n) : ('T', -$n);
  $n = sprintf("%b", $n); $n =~ tr/01/ST/;
  return $s . $n . 'L';
}

sub image_label {
  my ($n) = @_;
  $n = sprintf("%b", $n); $n =~ tr/01/ST/;
  return $n . 'L';
}

sub whitify {
  local ($_) = @_; tr/STL/\ \t\n/;
  return $_;
}

##-------- go to main
main();
# EOF
