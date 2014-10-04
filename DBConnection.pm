#!/usr/bin/perl

package DBConnection
{
	use strict;
	use DBI;
	use DBD::mysql;

	sub new
	{
		my $class = shift;
		my $dbname = shift;
		my $user = shift;
		my $password = shift;
		my $dsn = "dbi:mysql:$dbname";
		my $handle = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 0 }) 
		or die "Unable to connect: $DBI::errstr.\n";
		my $self = 
		{
			handle => $handle,
			custid => 0
		};
		bless $self, $class;
		return $self;
		
	}

	sub get_last_order
	{
		my ($self) = @_;
		my $statement = $self->{handle}->prepare("SELECT * FROM CUSTOMERS ORDER BY ID DESC LIMIT 1")
		or die "DB connection handle is corrupted.\n";
		$statement->execute() or die "DB connection handle is corrupted: $statement->errstr.\n";
		$self->{handle}->commit() or die "DB connection handle is corrupted: $statement->errstr}.\n";
		my @row = $statement->fetchrow_array();
		$self->{custid} = $row[0];
		return @row;
	}

	sub clear_last_order
	{
		my ($self) = @_;
		my $statement = $self->{handle}->prepare("DELETE FROM CUSTOMERS WHERE ID = $self->{custid}")
		or die "DB connection handle is corrupted.\n";
		$statement->execute() or die "DB connection handle is corrupted: $statement->errstr.\n";
		$self->{handle}->commit() or die "DB connection handle is corrupted: $statement->errstr.\n";
	}

	sub refresh_mask
	{
		my $self = shift;
		my @data = @_;
		my $statement = $self->{handle}->prepare("DELETE FROM IMASK")
		or die "DB connection handle is corrupted.\n";
		$statement->execute() or die "DB connection handle is corrupted: $statement->errstr.\n";
		for (@data)
		{
			#print $_;
			my $statement = $self->{handle}->prepare("INSERT INTO IMASK VALUES ($_)")
			or die "DB connection handle is corrupted: $statement->errstr.\n";
			$statement->execute() or die "DB connection handle is corrupted: $statement->errstr.\n";
		}
		$self->{handle}->commit() or die "DB connection handle is corrupted: $statement->errstr.\n";
	}

	sub DESTROY
	{
		my ($self) = @_;
		$self->{handle}->disconnect();
	}

}

1;
__END__