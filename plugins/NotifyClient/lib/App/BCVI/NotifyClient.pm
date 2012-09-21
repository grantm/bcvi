package App::BCVI::NotifyClient;

use warnings;
use strict;

our $VERSION = '1.00';

use POSIX qw(setsid);

my $default_idle_time     = 20;  # seconds
my $default_poll_interval =  5;  # seconds

sub send_command {
    my($self, @args) = @_;

    my $command = $self->opt('command') || $self->default_command();

    if($command eq 'notify') {
        # Check for TTY monitoring options; handle them and exit
        $self->_notify_handle_tty_monitoring(@args);
        # Otherwise drop through for default handling
    }

    return $self->SUPER::send_command(@args);
}


sub _notify_handle_tty_monitoring {
    my($self, @args) = @_;

    my %opt = $self->_notify_get_options(@args) or return;
    $opt{tty} ||= $self->_notify_current_tty;

    if($opt{idle}) {
        print "Starting background process to monitor $opt{tty} for $opt{idle} second idle period\n";
        print "Kill monitor with: bnotify --kill\n";
        $opt{output} = $default_poll_interval;
        $self->_notify_fork_bg_tty_monitor(sub {
            while(1) {
                $self->_notify_wait_for_idle(\%opt);
                $self->SUPER::send_command("terminal is idle");
                $self->_notify_exit if $opt{once};
                $self->_notify_wait_for_output(\%opt);
            }
        });
    }
    elsif($opt{output}) {
        print "Starting background process to monitor $opt{tty} for output\n";
        print "Kill monitor with: bnotify --kill\n";
        $opt{idle} = $default_idle_time;
        $self->_notify_fork_bg_tty_monitor(sub {
            $self->_notify_wait_for_idle(\%opt);
            while(1) {
                $self->_notify_wait_for_output(\%opt);
                $self->SUPER::send_command("output received");
                $self->_notify_exit if $opt{once};
                $self->_notify_wait_for_idle(\%opt);
            }
        });
    }
    elsif($opt{kill}) {
        $self->App::BCVI::Server::kill_current_listener();
        exit;
    }
}


sub _notify_wait_for_idle {
    my($self, $opt) = @_;

    my $sleep_time = $opt->{idle};
    while(1) {
        sleep($sleep_time);
        my $mtime = $self->_notify_tty_mtime($opt);
        my $idle = time() - $mtime;
        $sleep_time = $opt->{idle} - $idle;
        return if $sleep_time <= 0;
    }
}


sub _notify_wait_for_output {
    my($self, $opt) = @_;

    my $mtime = $self->_notify_tty_mtime($opt);
    while(1) {
        sleep($opt->{output});
        return if $self->_notify_tty_mtime($opt) != $mtime;
    }
}


sub _notify_tty_mtime {
    my($self, $opt) = @_;

    my @stat = stat($opt->{tty}) or die "stat($opt->{tty}): $!";
    return $stat[9];
}


sub _notify_current_tty {
    my $tty = readlink("/proc/self/fd/0");
    if(!$tty) {
        chomp( $tty = `tty` );
    }
    die "Unable to determine TTY\n" unless $tty;
    return $tty;
}


sub _notify_get_options {
    my($self, @args) = @_;

    local(@ARGV) = @args;
    my %opt = ();
    Getopt::Long::GetOptions(\%opt,
        '--idle|i:i',
        '--output|o:i',
        '--tty|t=s',
        '--once|1',
        '--kill|k',
    ) or exit;

    if(defined($opt{idle})) {
        $opt{idle} ||= $default_idle_time;
    }

    if(defined($opt{output})) {
        $opt{output} ||= $default_poll_interval;
    }

    if(defined($opt{tty}) and ! -e $opt{tty}) {
        die "No such file or device: $opt{tty}\n";
    }

    return %opt;
}


sub _notify_fork_bg_tty_monitor {
    my($self, $monitor_sub) = @_;

    fork() && exit;   # Parent retuns to shell child continues in background
    setsid();

    # We have this code lying around - might as well abuse it
    $self->App::BCVI::Server::save_pid();

    $monitor_sub->();

    exit;  # Shouldn't be reached
}


sub _notify_exit {
    my($self) = @_;

    unlink $self->pid_file;
    exit;
}


sub pid_file {
    my($self) = @_;

    my $path = $self->_notify_current_tty;
    $path =~ s{^.*(?=tty|pty|pts)}{}i;
    $path =~ s{^/}{};
    $path =~ s{\W+}{-}g;

    return File::Spec->catfile($self->conf_directory(), "notify-$path.pid");
}


App::BCVI->register_aliases(
    'test -n "${BCVI_CONF}"  && alias bnotify="bcvi --no-path-xlate -c notify --"',
);

App::BCVI->register_installable();

App::BCVI->hook_client_class();


1;

__END__

=head1 NAME

App::BCVI::NotifyClient - Send a notification message back to the user's desktop

=head1 SYNOPSIS

Send a message to the desktop notifications widget on your workstation:

  $ long-running-command; bnotify "long-running-command has finished"

or fork a background monitor to advise you when a subsequent command pauses for
input:

  $ bnotify -i
  Starting background process to monitor /dev/pts/0 for 5 second idle period
  $ sudo apt-get dist-upgrade
  ...

=head1 DESCRIPTION

This module is a plugin for C<bcvi> (see: L<App::BCVI>).  It uses the C<notify>
command to send a message back for display on the user's desktop.  This plugin
assumes a plugin back on the workstation will route the message to the desktop
notification applet or use some other mechanism to bring it to the attention of
the user.  The L<App::BCVI::NotifyDesktop> plugin is one implementation of the
workstation-end of the protocol.

The plugin registers the C<bnotify> alias as:

  alias bnotify="bcvi --no-path-xlate -c notify"

This alias might be used to signal the user that a long-running process has
completed on a remote server, for example:

  pg_dump intranet >intranet.dump ; bnotify "Database dump is finished!"

=head1 OPTIONS

Instead of simply sending a message, you can provide options to fork a
background process which will send you a message later when something
interesting happens (or doesn't):

=over 4

=item B<< --idle [<seconds>] >> (alias -i)

If the specified number of seconds (default 20) elapse with no output being
written to the TTY, you will receive a notification that the TTY is idle.  For
example you might use this option to fork a listener and then kick off a
dist-upgrade command.  If the command pauses awaiting input then you will be
notified.

=item B<< --output [<seconds>] >> (alias -o)

The C<--output> option is essentially the opposite of the C<--idle> - it will
tell you when there I<has> been output on the TTY.  By default it will check
every 5 seconds.  You can specify a different poll interval but this may mean
your notifications take longer to arrive.

When you specify C<--output>, the listener process will actually wait for 20
seconds B<of idle time> before it starts looking for output.  This allows you
to kick off the command you wish to monitor without getting alerts as you
type.

=item B<< --tty <path> >> (alias -t)

The C<--idle> and C<--output> options will monitor the current TTY by default.
This option allows you to monitor a different TTY or even a plain file.

=item B<< --once >> (alias -1)

The C<--idle> and C<--output> option will loop and notify you of each idle time
or output event.  Use the C<<--once>> option if you only want to be told about
the first event.  The background process will exit immediately after sending
the notification.

=item B<< --kill >> (alias -k)

Find and kill the background listener associated with the current TTY.

=back

=head1 SUPPORT

You can look for information at:

=over 4

=item * Source code

L<https://github.com/grantm/bcvi> (under 'plugins')

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-BCVI-NotifyClient>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-BCVI-NotifyClient>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-BCVI-NotifyClient>

=item * Search CPAN

L<http://search.cpan.org/dist/App-BCVI-NotifyClient>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Grant McLean E<lt>grantm@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

