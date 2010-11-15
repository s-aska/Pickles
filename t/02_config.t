
use strict;
use Plack::Test;
use Test::More tests => 22;
use MyApp::Config;
use Scalar::Util qw(refaddr);

{
    $ENV{'MYAPP_ENV'} = 'test';
    my $config = MyApp::Config->bootstrap;
    
    isa_ok( $config, 'MyApp::Config' );
    is @{$config->{__FILES}}, 2;
    like $config->{__FILES}->[0], qr/config\.pl$/;
    
    is $config->{Value}, '1';
    is $config->get('Value'), '1';
    
    is $config->{TestValue}, '2';
    is $config->get('TestValue'), '2';
    
    is $config->get('UndefinedValue', 2), '2';
    
    # __path_to()
    like $config->get('tmp_dir'), qr{^/};

    like $config->path_to('foo', 'bar.txt'), qr{^/};
    like $config->path_to('foo', 'bar.txt'), qr{MyApp/foo/bar\.txt$};
    is $config->path_to('/foo', 'bar', 'baz.txt'), '/foo/bar/baz.txt';
}

{
    # Check that both MYAPP_CONFIG and MYAPP_ENV are respected
    use Cwd ();
    use File::Spec;
    $ENV{'MYAPP_CONFIG'} = File::Spec->catfile(Cwd::cwd(), 't', '02_config_foo.pl');
    $ENV{'MYAPP_ENV'} = 'test';

    my ($config, $buffer);
    {
        local *STDERR;
        open STDERR, '>', \$buffer;
        $config = MyApp::Config->bootstrap;
    }

    isa_ok( $config, 'MyApp::Config' );
    is @{$config->{__FILES}}, 2;
}

{
    $ENV{'MYAPP_CONFIG'} = File::Spec->catfile(Cwd::cwd(), 't', '02_config_bar.pl');
    $ENV{'MYAPP_ENV'} = 'test';

    my ($config, $buffer);
    {
        local *STDERR;
        open STDERR, '>', \$buffer;
        $config = MyApp::Config->bootstrap;
    }
    if (ok $buffer) {
        like $buffer, qr/02_config_bar\.pl: Bogus error/;
        like $buffer, qr/02_config_bar_test\.pl: Bogus error/;
    }

    isa_ok( $config, 'MyApp::Config' );
    is @{$config->{__FILES}}, 2;
}

{
    my @files = (
        File::Spec->catfile(Cwd::cwd(), 't', '02_config_baz.pl'),
        File::Spec->catfile(Cwd::cwd(), 't', '02_config_baz_dev.pl'),
    );
    my $config = MyApp::Config->new( files => \@files );
    is $config->get('baz'), '1';
    is $config->get('dev'), '1';
    is @{$config->{__FILES}}, 2;
}
