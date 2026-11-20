vcl 4.1;
# /etc/varnish/default.vcl
# Typical chain: Nginx :443 (TLS) -> Varnish :6081 -> App :8080

backend default {
    .host = "127.0.0.1";
    .port = "8080";
    .probe = {
        .url = "/health";
        .interval = 5s;
        .timeout = 2s;
        .window = 5;
        .threshold = 3;
    }
}

acl purgers {
    "127.0.0.1";
}

sub vcl_recv {
    # Cache invalidation: curl -X PURGE http://127.0.0.1:6081/products
    if (req.method == "PURGE") {
        if (!client.ip ~ purgers) { return (synth(405, "Not allowed")); }
        return (purge);
    }

    # Never cache admin pages or authenticated users
    if (req.url ~ "^/admin" || req.http.Authorization) {
        return (pass);
    }

    # Static files: drop cookies so they can be cached
    if (req.url ~ "\.(css|js|png|jpg|svg|woff2)$") {
        unset req.http.Cookie;
    }
}

sub vcl_backend_response {
    # Default TTL if the app sends no Cache-Control
    if (!beresp.http.Cache-Control) {
        set beresp.ttl = 2m;
    }
    # Serve stale content for up to 1h if the backend is down
    set beresp.grace = 1h;
}

sub vcl_deliver {
    # Debug header: see HIT / MISS with curl -I
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
}
