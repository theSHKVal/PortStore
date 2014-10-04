#!/usr/bin/perl

package ThreadSubs;

use strict;
use MessageStruct;
use Data::Dumper;
use IO::Socket::INET;
use locale;
use DBConnection;
use POSIX qw/strftime/;

use constant SUCCESS_CODE => 0xAA;
use constant CMD_ORDER => 0x01;
use constant CMD_GMASK => 0x02;

sub send_orders
{
	my %config = @_;
	my $err;
	print STDERR "Tread 1 on\n" if ($config{"RunMode.Debug"});

	while (1)
	{
		my $sock;
		my $dbconn;
		my $message;
		
		eval
		{
			($sock, $dbconn, $message) = init(%config);
			while (my @data = $dbconn->get_last_order())
			{
				while (1)
				{
					$message->clear();
					$message->cmd(CMD_ORDER);
					$message->add($data[1]); #name
					$message->add($data[2]); #tel
					$message->add($data[3]); #mail
					$message->add($data[4]); #item
					eval
					{ 
						$message->send();
					};
					if ($@)
					{
						log_err("Failed to send order.\n");
						sleep($config{"Timeouts.Error"});
						redo;
					}
					$err = $message->recv();
					if (!$err && $message->cmd() == SUCCESS_CODE) 
					{
						$dbconn->clear_last_order();
						last;
					}
					else
					{
						log_err("The order has been sent, but server failed to answer.\n");
						sleep ($config{"Timeouts.Error"});
						redo;
					}
				}
				print STDERR "The order has been sent.\n" if ($config{"RunMode.Debug"});
			}
			print STDERR "All orders were sent\n" if ($config{"RunMode.Debug"});
			$sock->close();
			sleep ($config{"Timeouts.SendOrders"});
		};
		if ($@)
		{
			if (!$sock) { log_err("Can't open socket to send orders.\n"); }
			elsif (!$dbconn) { log_err("Can't connect to database to send orders.\n"); }
			else { log_err($@); $sock->close(); }
			sleep($config{"Timeouts.Error"});
		}
	}
}

sub get_mask
{
	my %config = @_;
	my $err;
	print STDERR "Tread 2 on\n" if ($config{"RunMode.Debug"});
		
	while (1)
	{
		my $sock;
		my $dbconn;
		my $message;

		eval
		{
			($sock, $dbconn, $message) = init(%config);
			while (1) 
			{
				$message->clear();
				$message->cmd(CMD_GMASK);
				eval 
				{
					$message->send();
				};
				if ($@) 
				{
					log_err("Failed to refresh mask while sending request.\n");
					sleep($config{"Timeouts.Error"});
					redo;
				}
				$err = $message->recv();
				print STDERR "Mask received. err: $err CMD: ".$message->cmd()."\n" if ($config{"RunMode.Debug"});
				if(!$err && $message->cmd() == SUCCESS_CODE)
				{ 
					$dbconn->refresh_mask(split('\n', $message->data())); 
					last;
				} 
				else 
				{ 
					log_err("Failed to refresh mask while receiving answer.\n");
					sleep($config{"Timeouts.Error"});
					redo;
				}
			}
			print STDERR "Mask refreshed\n" if ($config{"RunMode.Debug"});
			$sock->close();
			sleep ($config{"Timeouts.GetMask"});
		};
		if ($@)
		{
			if (!$sock) { log_err("Can't open socket to refresh mask.\n"); }
			elsif (!$dbconn) { log_err("Can't connect to database to refresh mask.\n"); }
			else { log_err($@); $sock->close(); }
			sleep($config{"Timeouts.Error"});
		}
	}

}

sub log_err #($error_string)
{
	my $err = shift;
	open (F, '>>errors.log');
	flock (F, 2); #exclusive lock on file handle; object will be released at the end of the scope
	print F (strftime('%d.%m.%Y %H:%M:%S', localtime), " ", $err);
	close (F);
}

sub init #(config)
{
	my %config = @_;
	my $sock = new IO::Socket::INET(Proto => "tcp", PeerAddr => $config{"Connection.IP"}, PeerPort => $config{"Connection.Port"});
	my $dbconn = new DBConnection($config{"DataBase.DBName"}, $config{"DataBase.User"}, $config{"DataBase.Password"});
	my $message = new MessageStruct($config{"Connection.ID"}, $sock, $config{"Timeouts.Error"});
	return ($sock, $dbconn, $message);
}

1;

__END__

$pid = fork();
if pid = 0 exit 0