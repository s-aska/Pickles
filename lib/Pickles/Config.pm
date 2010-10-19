package Pickles::Config;
use strict;
use Path::Class;
use Plack::Util::Accessor qw(appname home);
use Pickles::Util qw(env_value);

sub instance {
    my $class = shift;
    return $class if ref $class;
    no strict 'refs';
    my $instance = \${ "$class\::_instance" };
    defined $$instance ? $$instance : ($$instance = $class->_load);
}


sub _load {
    my $class = shift;
    my $self = bless {}, $class;
    (my $appname = $class) =~ s/::Config$//;
    $self->{appname} = $appname;
    $self->{ACTION_PREFIX} = '';
    $self->setup_home;
    $self->load_config;
    $self;
}

sub get {
    my( $self, $key, $default ) = @_;
    return defined $self->{$key} ? $self->{$key} : $default;
}

sub setup_home {
    my $self = shift;
    if ( my $home = env_value('HOME', $self->appname) ) { # MYAPP_HOME
        $self->{home} = dir( $home );
    }
    elsif ($ENV{'PICKLES_HOME'}) {
        $self->{home} = dir( $ENV{'PICKLES_HOME'} );
    }
    else {
        my $class = ref $self;
        (my $file = "$class.pm") =~ s|::|/|g;
        if (my $inc_path = $INC{$file}) {
            (my $path = $inc_path) =~ s/$file$//;
            my $home = dir($path)->absolute->cleanup;
            $home = $home->parent while $home =~ /b?lib$/;
            $self->{home} = $home;
        }
    }
}

sub load_config {
    my $self = shift;
    my $files = $self->get_config_files;
    my %config;

    # In 5.8.8 at least, putting $self in an evaled code produces
    # extra warnings (and possibly break the behavior of __path_to)
    # so we create a private closure, and plant the closure into
    # the generated packes
    my $path_to = sub { $self->path_to(@_) };

    for my $file( @{$files} ) {
        my $pkg = $file;
        $pkg =~ s/([^A-Za-z0-9_])/sprintf("_%2x", unpack("C", $1))/eg;

        my $fqname = sprintf '%s::%s', ref $self, $pkg;
        { # XXX This is where we plant that closure
            no strict 'refs';
            *{"$fqname\::__path_to"} = $path_to;
        }

        my $config_pkg = sprintf <<'SANDBOX', $fqname;
package %s;
{
    my $conf = do $file or die $!;
    $conf;
}
SANDBOX
        my $conf = eval $config_pkg || +{};
        %config = (
            %config,
            %{$conf},
        );
    }
    $self->{__FILES} = $files;
    $self->{__TIME} = time;
    for my $key( keys %config ) {
        $self->{$key} = $config{$key};
    }
    \%config;
}

sub get_config_files {
    my $self = shift;
    my @files;
    my $base = $self->path_to('config.pl');
    push @files, $base if -e $base;
    if ( my $config_file = env_value('CONFIG', $self->appname) ) {
        if ( $config_file =~ m{^/} ) {
            push @files, $config_file;
        }
        else {
            push @files, $self->path_to( $config_file );
        }
    }
    if ( my $env = env_value('ENV', $self->appname) ) {
        my $filename = sprintf 'config_%s.pl', $env;
        push @files, $self->path_to( $filename );
    }
    return \@files;
}

sub path_to {
    my( $self, @path ) = @_;
    file( $self->home, @path )->stringify;
}

1;

__END__
