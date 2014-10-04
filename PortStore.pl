#!/usr/bin/perl

use Config::Simple;
use ThreadSubs;
use threads;
use strict;

#my $pid = fork();
#if ($pid) { kill('INT', $$); }

$SIG{INT}=\&term;
sub term 
{
	print STDERR "\nClient stopped.\n";
	exit(0);
}

my %config;
Config::Simple->import_from('config.cf', \%config);

$| = 1 if ($config{"RunMode.Debug"});

print STDERR "Client started\n";

threads->create(\&ThreadSubs::send_orders, %config)->detach();
threads->create(\&ThreadSubs::get_mask, %config)->detach();

while (1)
{
	sleep (1);
}

__END__
