bcvi - Back-channel vi
======================

This is a handy little utility for people who use SSH to connect to servers
but like to use gvim (a GUI version of vim) to edit files.  When you're
connected to a remote server (say www.example.com) and type a command like:

    bcvi .bashrc

The bcvi utility sends a message back to your workstation which causes a
command like this to be run:

    gvim scp://www.example.com/.bashrc

Because the editor process is running on your workstation:

 * all your local .vimrc macros, settings, etc are available
 * the GUI is snappy and responsive (unlike an X-forwarded app)
 * when you save the file, it is transparently uploaded via scp
 * your remote shell window is available to run other commands


Copyright and Licence
---------------------

Copyright (C) 2007-2010 Grant McLean

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

