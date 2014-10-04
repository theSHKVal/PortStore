package MessageStruct;
use String::CRC32;
use utf8;
use locale;
use Encode qw(decode encode);
use Socket;
use strict;

use constant SUCCESS_CODE => 0xAA;
use constant FAIL_CODE => 0x00;

sub new 
{
	die "MessageStruct constructor has been called with a wrong argument list\n" unless @_ == 4;
	my $class = shift;
	my $termID = shift;
	my $sock = shift;
	my $timeout = shift;
	my $self = {termID => $termID, cmd => 0, data => "", dlen => 0, SOCKET => $sock};
	$sock->setsockopt(SOL_SOCKET, SO_RCVTIMEO, pack('l!l!', $timeout, 0)) or die "setsockopt: $!";
	bless $self, $class;
}

sub cmd 
{
	my $self = shift;
	$self -> {cmd} = shift if(@_);
	$self -> {cmd};
}

sub termID 
{
	my $self = shift;
	$self -> {termID} = shift if(@_);
	$self -> {termIDrecv};
}

sub data 
{
	my $self = shift;
	$self -> {data};
}

sub dlen 
{
	my $self = shift;
	$self -> {dlen};
}

sub clear {
		my $self = shift;
		$self -> {data} = "";
		$self -> {dlen} = 0;
}

sub add 
{
		my $self = shift;
		my $str = encode('UTF-8', shift);
		$self -> {data} .= $str."\n";
		$self -> {dlen} ++;
} 

sub send 
{
	my $self = shift;
	my $cont = $self -> {termID} . "\n" . $self -> {cmd} . "\n" . $self -> {dlen} . "\n" . $self -> {data};
	$cont .= crc32($cont)."\n";
	my $sock = $self->{SOCKET};
	$sock->send($cont, 0) != length $cont;
}

sub recv 
{
	my $self = shift;
	my $sock = $self->{SOCKET};
	my $crc;
	eval 
	{

	   	#receiving id
		$_ = <$sock>;
		die "conn err1\n" unless defined $_;
		chomp;
		$self->{termIDrecv} = $_;

		#receiving command
		$_ = <$sock>;
		die "conn err1\n" unless defined $_;
		chomp;
		$self->{cmd} = $_;

		#receiving length
		$_ = <$sock>;
		die "conn err1\n" unless defined $_;
		chomp;
		$self->{dlen} = $_;

		#receiving data
		$self->{data} = "";
		for (my $i = 0; $i < $self->{dlen}; ++$i) {
			$_ = <$sock>;
			die "conn err1\n" unless defined $_;
			$self->{data} .= $_;
		}

		#receiving crc
		$_ = <$sock>;
		die "conn err1\n" unless defined $_;
		chomp;
		$crc = $_;
	
	};
	if ($@) {
		undef $@;
		return 1;
	}

	#checking crc
	my $cont = $self -> {termIDrecv} . "\n" . $self -> {cmd} . "\n" . $self -> {dlen} . "\n" . $self -> {data};
	return 2 if(crc32($cont) != $crc);

	return 0;
}

sub ack 
{
	my $this = shift;
	$this->cmd(SUCCESS_CODE);
	$this->clear();
	$this->send();
}

sub nak 
{
	my $this = shift;
	$this->cmd(FAIL_CODE);
	$this->clear();
	$this->send();
}

1;
__END__
