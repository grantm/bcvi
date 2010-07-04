package App::BCVI::InstallManager;

use warnings;
use strict;

use Digest::MD5;
use Fcntl;
use SDBM_File;

our $VERSION = '1.01';

my($source_signature, %sig_db, $db_file);

sub update_all_installs {
    my($self) = @_;

    if(my $arg = $self->opt('update-all')) {  # usual value '' is false
        if($arg eq 'list') {
            return $self->list_all_installs
        }
        elsif($arg =~ m{^-(.+)$}) {
            return $self->untrack_host($1);
        }
        die "Unrecognised argument ('$arg') to --update-all\n";
    }

    my $sig = $self->install_source_signature();
    my $host_sigs = $self->all_install_signatures();
    my @hosts = grep { $host_sigs->{$_} ne $sig } sort keys %$host_sigs;
    if(@hosts) {
        $self->install_to_hosts(@hosts);
    }
    else {
        print "All known targets are up to date\n";
        exit(0);
    }
}


sub list_all_installs {
    my($self) = @_;

    my $valid = $self->install_source_signature();

    $self->tie_install_sig_db();

    foreach my $key (sort keys %sig_db) {
        my $sig = $sig_db{$key};
        if($sig eq $valid) {
            printf("%-30s  OK\n", $key);
        }
        else {
            printf("%-30s  Needs update\n", $key);
        }
    }

    $self->untie_install_sig_db();
}


sub untrack_host {
    my($self, $host) = @_;

    print "Discarding install info for $host\n";
    $self->tie_install_sig_db();
    delete $sig_db{$host};
    $self->untie_install_sig_db();
}


sub install_to_host {
    my($self, $host) = @_;

    my $sig = $self->install_source_signature();
    $self->SUPER::install_to_host($host);
    $self->set_install_signature($host=> $sig);
}


sub tie_install_sig_db {
    my($self) = @_;
    $db_file ||= File::Spec->catfile($self->conf_directory, 'install.db');
    tie(%sig_db, 'SDBM_File', $db_file,  O_RDWR|O_CREAT, 0666)
        or die "Couldn't tie SDBM file $db_file: $!; aborting";
}


sub untie_install_sig_db {
    my($self) = @_;
    untie %sig_db;
}


sub set_install_signature {
    my($self, $host, $sig) = @_;
    $self->tie_install_sig_db();
    $sig_db{$host} = $sig;
    $self->untie_install_sig_db();
}


sub all_install_signatures {
    my($self) = @_;
    $self->tie_install_sig_db();
    my $all = { %sig_db };
    $self->untie_install_sig_db();
    return $all;
}


sub install_source_signature {
    my($self) = @_;

    return $source_signature if $source_signature;

    my $md5 = Digest::MD5->new;
    open my $fh, '<', $0 or die "open($0): $!";
    $md5->addfile($fh);
    close($fh);

    foreach my $path ( $self->installable_files ) {
        open my $fh, '<', $path or die "open($path): $!";
        $md5->addfile($fh);
        close($fh);
    }
    $source_signature = substr($md5->hexdigest(), 0, 8);
}


App::BCVI->register_option(
    name        => 'update-all',
    arg_spec    => ':s',
    dispatch_to => 'update_all_installs',
    summary     => 'update bcvi on all tracked hosts',
    description => <<'END_POD'
This option is provided by the InstallManager plugin.  It causes C<--install>
to be run against each host where bcvi has been installed but is now out of
date.

Two sub options are available: You can list all known hosts where bcvi has been
installed, with: C<< --update-all=list >>.  You can also discard a hostname from
being tracked with: C<< --update-all=-hostname >>.
END_POD
);


App::BCVI->hook_client_class();

1;

__END__

=head1 NAME

App::BCVI::InstallManager - Track where bcvi is installed, to manage updates


=head1 DESCRIPTION

This module is a plugin for C<bcvi> (see: L<App::BCVI>).  It tracks the names
of servers where bcvi has been installed using the C<< bcvi --install <host> >>
command.

The plugin also adds the C<--update-all> option to the C<bcvi> command.  This
option identifies hosts where an old version of bcvi is installed and re-runs
the C<--install> against those hosts to update the script and aliases.

To get a list of all the hosts where C<bcvi> is installed, you can run:

  bcvi --update-all=list

To remove a host from the list, use:

  bcvi --update-all=-hostname

Note: Although this plugin does hook into the C<--install> process, it does not
change the behaviour of that process.  In particular it will B<not> block an
attempt to install the same version of bcvi as is already installed on a host.


=head1 SUPPORT

You can look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-BCVI-InstallManager>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-BCVI-InstallManager>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-BCVI-InstallManager>

=item * Search CPAN

L<http://search.cpan.org/dist/App-BCVI-InstallManager>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Grant McLean E<lt>grantm@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

