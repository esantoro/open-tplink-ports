#!/usr/bin/env perl

#
# Perl script to open ports on a TP-LINK TD8841 router
# License: GPLv3 or any later published by the Free
# Software Foundation
#
# Author: Emanuele Santoro <manu@santoro.tk>
# Website: http://santoro.tk
#
#


use strict ;
use warnings ;
use diagnostics ;


use feature 'say';

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

use Net::Telnet ();
my $t = new Net::Telnet (Timeout => 10,
			 Prompt => '/\>/');

my $host = "192.168.1.1" ;
my $username = "admin" ;
my $passwd = "admin" ;
my $output = '';

$t->open($host);
$t->login($username, $passwd);
my @lines = $t->cmd("iptables -t nat -L PREROUTING --line-numbers");

if (grep /tcp dpt:ssh to:192.168.1.200/, @lines ) {
  say "Port forwarding enabled, quitting" ;
  exit 0 ;
}
else {
  say "Port forwarding rule not detected" ;

#  my @lines = $t->cmd("THIS IS A BLANK LINE, FOR TESTING PURPOSE ONLY") ;

  @lines = $t->cmd("iptables -I FORWARD 1 -i ppp_8_35_1 -o br0 -p tcp --dport 22 -j ACCEPT");
  $output .= join '\n', @lines ;

  @lines = $t->cmd("iptables -t nat -A PREROUTING -i ppp_8_35_1 -p tcp --dport 22 -j DNAT --to-destination 192.168.1.200") ;
  $output .= join '\n', @lines ;

  if (length trim $output ) {
    say STDERR "WARNING: SOMETHING WENT WRONG!!";
    say STDERR "Debugging data (command output):" ;
    say "---" ;
    say STDERR join '\n', @lines ;
    say "---" ;
    exit 1 ;
  }
  else {
    say "Everything worked smoothly. Good job!" ;
    exit 0 ;
  }
}

