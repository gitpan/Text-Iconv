package Text::Iconv;
# @(#) $Id: Iconv.pm,v 1.4 2004/06/28 19:06:17 mxp Exp $
# Copyright (c) 2004 Michael Piotrowski

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
	convert
);
$VERSION = '1.3';

bootstrap Text::Iconv $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the documentation for the module.

=head1 NAME

Text::Iconv - Perl interface to iconv() codeset conversion function

=head1 SYNOPSIS

  use Text::Iconv;
  $converter = Text::Iconv->new("fromcode", "tocode");
  $converted = $converter->convert("Text to convert");

=head1 DESCRIPTION

The B<Text::Iconv> module provides a Perl interface to the iconv()
function as defined by the Single UNIX Specification.  The convert()
method converts the encoding of characters in the input string from
the I<fromcode> codeset to the I<tocode> codeset, and returns the
result.

Settings of I<fromcode> and I<tocode> and their permitted combinations
are implementation-dependent.  Valid values are specified in the
system documentation

As an experimental feature, this version of B<Text::Iconv> objects
provide the retval() method:

  $result = $converter->convert("lorem ipsum dolor sit amet");
  $retval = $converter->retval;

This method can be called after calling convert().  It returns the
return value of the underlying iconv() function for the last
conversion; according to the Single UNIX Specification, this value
indicates "the number of non-identical conversions performed."  Note,
however, that iconv implementations vary widely in the interpretation
of this specification.

When called before the first call to convert(), or if an error occured
during the conversion, retval() returns B<undef>.

=head1 ERRORS

If the conversion can't be initialized an exception is raised (using
croak()).

I<Text:Iconv> provides a class attribute B<raise_error> and a
corresponding class method for setting and getting its value.  The
handling of errors during conversion depends on the setting of this
attribute.  If B<raise_error> is set to a true value, an exception is
raised; otherwise, the convert() method only returns B<undef>.  By
default B<raise_error> is false.  Example usage:

  Text::Iconv->raise_error(1);     # Conversion errors raise exceptions
  Text::Iconv->raise_error(0);     # Conversion errors return undef
  $a = Text::Iconv->raise_error(); # Get current setting

Consult L<iconv(3)> for details on errors that might occur.

Converting undef, e.g.,

  $converted = $converter->convert(undef);

always returns undef.  This is not considered an error.

=head1 NOTES

The supported codesets, their names, the supported conversions, and
the quality of the conversions are all system-dependent.

=head1 AUTHOR

Michael Piotrowski <mxp@dynalabs.de>

=head1 SEE ALSO

iconv(1), iconv(3)

=cut
