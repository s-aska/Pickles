

use strict;
use Plack::Test;
use Test::More tests => 4;
use lib "./t/MyApp/lib";
use MyApp::Context;
use MyApp::View::Xslate;
use HTTP::Request;
use HTTP::Response;
use HTTP::Message::PSGI;

my $view = MyApp::View::Xslate->new;
isa_ok( $view, 'MyApp::View::Xslate' );

my $req = HTTP::Request->new( GET => 'http://localhost/foo/bar' );
my $env = $req->to_psgi;
my $c = MyApp::Context->new( $env );
my $config = $view->merge_config( $c );

$c->stash->{'var'} = 'var1';
$c->_prepare; # set template.
my $html = $view->render( $c );
like( $html, qr/Foo/ );
like( $html, qr/MyApp/ );
like( $html, qr{<div>var1</div>});
