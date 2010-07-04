package App::BCVI::NotifyClient;

use warnings;
use strict;

our $VERSION = '1.00';


App::BCVI->register_aliases(
    'test -n "${BCVI_CONF}"  && alias bnotify="bcvi --no-path-xlate -c notify"',
);

App::BCVI->register_installable();


1;

__END__

=head1 NAME

App::BCVI::NotifyClient - Send a notification message back to the user's desktop

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


=head1 SUPPORT

You can look for information at:

=over 4

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

