package Test::NoTabs;
# ABSTRACT: Check the presence of tabs in your project

use strict;
use warnings;

our $VERSION = '2.02';

use Test::Builder;
use File::Spec;
use FindBin qw($Bin);
use File::Find ();

our $PERL    = $^X || 'perl';
our $UNTAINT_PATTERN  = qr|^([-+@\w./:\\]+)$|;
our $PERL_PATTERN     = qr/^#!.*perl/;

my %file_find_arg = ("$]" <= 5.006) ? () : (
    untaint => 1,
    untaint_pattern => $UNTAINT_PATTERN,
    untaint_skip => 1,
);

my $Test  = Test::Builder->new;
my $updir = File::Spec->updir();

sub import {
    my $self   = shift;
    my $caller = caller;
    {
        no strict 'refs';
        *{$caller.'::notabs_ok'} = \&notabs_ok;
        *{$caller.'::all_perl_files_ok'} = \&all_perl_files_ok;
    }
    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub _all_perl_files {
    my @all_files = _all_files(@_);
    return grep { _is_perl_module($_) || _is_perl_script($_) } @all_files;
}

sub _all_files {
    my @base_dirs = @_ ? @_ : File::Spec->catdir($Bin, $updir);
    my @found;
    my $want_sub = sub {
        return if ($File::Find::dir =~ m![\\/]?CVS[\\/]|[\\/]?\.svn[\\/]!); # Filter out cvs or subversion dirs/
        return if ($File::Find::dir =~ m![\\/]?blib[\\/]libdoc$!); # Filter out pod doc in dist
        return if ($File::Find::dir =~ m![\\/]?inc!); # Remove Module::Install
        return if ($File::Find::dir =~ m![\\/]?blib[\\/]man\d$!); # Filter out pod doc in dist
        return if ($File::Find::name =~ m!Build$!i); # Filter out autogenerated Build script
        return unless (-f $File::Find::name && -r _);
        push @found, File::Spec->no_upwards( $File::Find::name );
    };
    my $find_arg = {
        %file_find_arg,
        wanted   => $want_sub,
        no_chdir => 1,
    };
    File::Find::find( $find_arg, @base_dirs);
    return @found;
}

sub notabs_ok {
    my $file = shift;
    my $test_txt = shift || "No tabs in '$file'";
    $file = _module_to_path($file);
    open my $fh, $file or do { $Test->ok(0, $test_txt); $Test->diag("Could not open $file: $!"); return; };
    my $line = 0;
    while (<$fh>) {
        $line++;
        next if (/^\s*#/);
        next if (/^\s*=(head[1234]|over|item|begin|for|encoding)/ .. (/^\s*=(cut|back|end)/ || eof($fh)));
        last if (/^\s*(__END__|__DATA__)/);
        if ( /\t/ ) {
          $Test->ok(0, $test_txt . " on line $line");
          return 0;
        }
    }
    $Test->ok(1, $test_txt);
    return 1;
}

sub all_perl_files_ok {
    my @files = _all_perl_files( @_ );
    _make_plan();
    foreach my $file ( sort @files ) {
      notabs_ok($file, "No tabs in '$file'");
    }
}

sub _is_perl_module {
    $_[0] =~ /\.pm$/i || $_[0] =~ /::/;
}

sub _is_perl_script {
    my $file = shift;
    return 1 if $file =~ /\.pl$/i;
    return 1 if $file =~ /\.t$/;
    open (my $fh, $file) or return;
    my $first = <$fh>;
    return 1 if defined $first && ($first =~ $PERL_PATTERN);
    return;
}

sub _module_to_path {
    my $file = shift;
    return $file unless ($file =~ /::/);
    my @parts = split /::/, $file;
    my $module = File::Spec->catfile(@parts) . '.pm';
    foreach my $dir (@INC) {
        my $candidate = File::Spec->catfile($dir, $module);
        next unless (-e $candidate && -f _ && -r _);
        return $candidate;
    }
    return $file;
}

sub _make_plan {
    unless ($Test->has_plan) {
        $Test->plan( 'no_plan' );
    }
    $Test->expected_tests;
}

sub _untaint {
    my @untainted = map { ($_ =~ $UNTAINT_PATTERN) } @_;
    return wantarray ? @untainted : $untainted[0];
}

1;
__END__

=pod

=head1 SYNOPSIS

C<Test::NoTabs> lets you check the presence of tabs in your perl code. It
report its results in standard C<Test::Simple> fashion:

  use Test::NoTabs tests => 1;
  notabs_ok( 'lib/Module.pm', 'Module is tab free');

Module authors can include the following in a t/notabs.t and have C<Test::NoTabs>
automatically find and check all perl files in a module distribution:

  use Test::NoTabs;
  all_perl_files_ok();

or

  use Test::NoTabs;
  all_perl_files_ok( @mydirs );

=head1 DESCRIPTION

This module scans your project/distribution for any perl files (scripts,
modules, etc) for the presence of tabs.

=head1 FUNCTIONS

=head2 all_perl_files_ok( [ @directories ] )

Applies C<notabs_ok()> to all perl files found in C<@directories> (and sub
directories). If no <@directories> is given, the starting point is one level
above the current running script, that should cover all the files of a typical
CPAN distribution. A perl file is *.pl or *.pm or *.t or a file starting
with C<#!...perl>

If the test plan is defined:

  use Test::NoTabs tests => 3;
  all_perl_files_ok();

the total number of files tested must be specified.

=head2 notabs_ok( $file [, $text] )

Run a tab check on C<$file>. For a module, the path (lib/My/Module.pm) or the
name (My::Module) can be both used.

=head1 ACKNOWLEDGEMENTS

=for stopwords Emanuele Florian Lindner Ragwitz Zeppieri rafl

Inspired by some code written by Paul Lindner.

L<Test::Strict> was used as an example when creating this module and
distribution.

Rick Myers and Emanuele Zeppieri also provided valuable feedback.

Patch to fix warnings provided by Florian Ragwitz (rafl)

Currently maintained by Tomas Doran (t0m) C<bobtfish@bobtfish.net>

=head1 SEE ALSO

L<Test::More>, L<Test::Pod>. L<Test::Distribution>, L<Test::NoWarnings>

=cut
