package App::BCVI::NotifyDesktop;

use warnings;
use strict;

our $VERSION = '1.01';

use Encode qw(encode decode);


sub execute_notify {
    my($self) = @_;

    my $title = "Notification from " . $self->calling_host();

    my $message = decode('utf8', $self->read_request_body());

    eval { require Desktop::Notify; };
    if($@) {
        warn "Desktop::Notify is not installed.\n\n$title:\n$message\n\n";
        return;
    }

    my $notify = Desktop::Notify->new();

    my $notification = $notify->create(
        summary => $title,
        body    => $message,
        timeout => 10000,
    );

    $notification->show();
}


App::BCVI->register_command(
    name        => 'notify',
    description => <<'END_POD'
Send a message which will be displayed as a notification on the user's desktop
(where the bcvi listener is running).  Typically used with the
C<--no-path-xlate> option so that any arguments are passed as text strings
rather than as a list of filenames.

The client side for this command (the 'bnotify' alias) also accepts C<--idle>
and C<--output> options which cause it to fork a background process to monitor
the current TTY and notify you of idle time (e.g. if a process is waiting for
input), For more info see:

  bcvi --plugin-help NotifyClient

END_POD
);

App::BCVI->hook_server_class();


1;

__END__

=head1 NAME

App::BCVI::NotifyDesktop - Display a notification message at the user's desktop


=head1 DESCRIPTION

This module is a plugin for C<bcvi> (see: L<App::BCVI>).  It displays messages
from the C<bcvi> client using the Desktop Notification  protocol.  It assumes
the user has also installed a plugin (such as App::BCVI::NotifyClient) to send
the messages.

The module uses the L<Desktop::Notify> module to generate DBus messages for
display by a notification applet running in the user's desktop environment.


=head1 SUPPORT

You can look for information at:

=over 4

=item * Source code

L<https://github.com/grantm/bcvi> (under 'plugins')

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-BCVI-NotifyDesktop>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-BCVI-NotifyDesktop>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-BCVI-NotifyDesktop>

=item * Search CPAN

L<http://search.cpan.org/dist/App-BCVI-NotifyDesktop>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Grant McLean E<lt>grantm@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

