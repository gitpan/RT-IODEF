use inc::Module::Install;

RTx('RT-IODEF');
license('GPL Version 2');
author('Barely3am Solutions <wes@barely3am.com>');
version_from('lib/RT/IODEF.pm');

{ # check RT version
    my @v = split /\./, "$RT::VERSION";
    unless ($v[0]>=3 && $v[1]>=8 && ($v[2]>=1 || $v[2]eq'HEAD')) {
        die "RT-IODEF and newer needs RT 3.8.2 at least, you have $RT::VERSION";
    }
}

# XXX: This should be reported by M::I::RTx
my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
unshift @INC, $local_lib_path, $lib_path;

requires('XML::IODEF::Simple'   => '0.01');

auto_install();

tests("t/*.t t/*/*.t");

WriteAll();
