router {
    connect '/' => { controller => 'Root', action => 'index' };
    connect '/foo' => { controller => 'Root', action => 'foo' };
    connect '/foo/bar' => { controller => 'Foo', action => 'bar' };
    connect '/foo/post' => { controller => 'Foo', action => 'post', }, { method => 'POST' };
    connect '/foo/multibyte_args/{ja}/' => { controller => 'Foo', action => 'multibyte_args', };
    connect qr{/foo/multibyte_array_args/(.+)/(.+)/} => { controller => 'Foo', action => 'multibyte_args', };


    connect '/redirect' => { controller => 'Root', action => 'redirect' };
    connect '/redirect2' => { controller => 'Root', action => 'redirect2' };
    connect '/redirect2' => { controller => 'Root', action => 'redirect2' };
    connect '/redirect_and_abort' => { controller => 'Root', action => 'redirect_and_abort' };
    connect '/form' => { controller => 'Root', action => 'form' };
    connect '/count' => { controller => 'Root', action => 'count' };
    connect '/items/:id' => { 'controller' => 'Item', action => 'view', };
    connect '/bar/:action' => {'controller' => 'Bar',};
};
