# 🌐 Web Servers, Applications and Databases for DevOps

A simple, beginner-friendly guide to the "middle" of every system: the **web servers** that receive traffic, the **caches** that make it fast, how **applications are built and run**, and the **databases and queues** that keep the data. Written for DevOps interns who want to go from zero to confident.

Every topic follows the same pattern: **what it is**, **why DevOps people care**, and **something small you can try right now**. Read it in order, type every command yourself, and finish with the labs at the end.

![Learning path](images/00-roadmap.png)

---

## 📚 Table of Contents

**PART 1: Web Servers and Proxies (Serve and Route Traffic)**

1. [Start Here: Why This Matters for DevOps](#1-start-here-why-this-matters-for-devops)
2. [How a Web Request Works](#2-how-a-web-request-works)
3. [Web Server vs Application Server](#3-web-server-vs-application-server)
4. [Install Nginx and First Commands](#4-install-nginx-and-first-commands)
5. [How Nginx Works Inside](#5-how-nginx-works-inside)
6. [Nginx Configuration Structure](#6-nginx-configuration-structure)
7. [Location Blocks](#7-location-blocks)
8. [Virtual Hosts (Server Blocks)](#8-virtual-hosts-server-blocks)
9. [Reverse Proxy](#9-reverse-proxy)
10. [Load Balancing](#10-load-balancing)
11. [SSL/TLS and HTTPS](#11-ssltls-and-https)
12. [Apache HTTPD](#12-apache-httpd)
13. [HAProxy](#13-haproxy)
14. [Caddy](#14-caddy)
15. [Choosing a Web Server](#15-choosing-a-web-server)

**PART 2: Caching (Make It Fast)**

16. [Caching Basics](#16-caching-basics)
17. [HTTP Cache Headers](#17-http-cache-headers)
18. [Varnish](#18-varnish)
19. [CDN Concepts: Cloudflare and CloudFront](#19-cdn-concepts-cloudflare-and-cloudfront)

**PART 3: How Applications Are Built and Run (Ship the App)**

20. [From Source Code to Running App](#20-from-source-code-to-running-app)
21. [Build Tools Overview](#21-build-tools-overview)
22. [Maven](#22-maven)
23. [Gradle](#23-gradle)
24. [npm](#24-npm)
25. [pip](#25-pip)
26. [Make](#26-make)
27. [Artifact Repositories: Nexus and Artifactory](#27-artifact-repositories-nexus-and-artifactory)
28. [Monolith vs Microservices](#28-monolith-vs-microservices)
29. [The 12-Factor App](#29-the-12-factor-app)

**PART 4: Databases at DevOps Level (Keep Data Safe)**

30. [SQL vs NoSQL](#30-sql-vs-nosql)
31. [MySQL and PostgreSQL Basics](#31-mysql-and-postgresql-basics)
32. [Backups and Restore](#32-backups-and-restore)
33. [Replication](#33-replication)
34. [MongoDB](#34-mongodb)
35. [Redis](#35-redis)
36. [Cassandra](#36-cassandra)
37. [Message Queues and RabbitMQ](#37-message-queues-and-rabbitmq)
38. [Kafka Basics](#38-kafka-basics)
39. [Database Migrations: Flyway and Liquibase](#39-database-migrations-flyway-and-liquibase)

**PART 5: Practice**

40. [The Big Picture](#40-the-big-picture)
41. [Practice Labs](#41-practice-labs)
42. [Troubleshooting Playbook](#42-troubleshooting-playbook)
43. [Cheat Sheet](#43-cheat-sheet)
44. [Interview Questions](#44-interview-questions)
45. [Reference](#45-reference)

---

# PART 1: Web Servers and Proxies (Serve and Route Traffic)

---

## 1. Start Here: Why This Matters for DevOps

Developers write the application. **DevOps makes sure the world can reach it, quickly and safely, and that its data never disappears.** That means you own everything between the user's browser and the database.

Here is what goes wrong when people don't understand this layer:

| What people say | What it actually is |
|-----------------|--------------------|
| "The site shows **502 Bad Gateway**" | Nginx is fine, but the app behind it is down or on the wrong port |
| "The site is slow only at lunchtime" | No caching, no load balancing, one server doing everything |
| "Browser says **Not Secure**" | No TLS certificate, or it expired (Let's Encrypt renew failed) |
| "Works on my machine, not in prod" | Config hard-coded in the code instead of environment variables (12-factor) |
| "The build downloaded a different library version" | No lock file, no artifact repository |
| "We lost a day of orders" | Backups existed but nobody ever tested a restore |
| "The deploy broke the database" | Someone ran SQL by hand instead of versioned migrations |

None of these are coding problems. They are **DevOps problems**, and this guide teaches you to prevent and fix each one.

### 1.1 What you will be able to do after this guide

- Explain exactly what happens when someone opens a website
- Configure Nginx as a web server, reverse proxy and load balancer, with HTTPS
- Read Apache, HAProxy and Caddy configs and know when to use each
- Explain caching layers, cache headers, Varnish and CDNs
- Build Java, Node and Python apps with Maven, Gradle, npm, pip and Make
- Store artifacts in Nexus / Artifactory and explain why
- Compare monolith vs microservices and apply the 12-Factor principles
- Back up, restore and replicate MySQL / PostgreSQL
- Explain when to use MongoDB, Redis, Cassandra, RabbitMQ and Kafka
- Version database changes with Flyway and Liquibase

### 1.2 The 10 words you will see everywhere

| Word | Plain meaning |
|------|---------------|
| **Web server** | Program that answers HTTP requests (Nginx, Apache, Caddy) |
| **Reverse proxy** | A server that sits in front of your apps and forwards requests to them |
| **Load balancer** | Spreads requests across several servers |
| **Upstream / backend** | The servers behind the proxy that do the real work |
| **TLS / SSL** | Encryption that turns `http://` into `https://` |
| **Cache** | A saved copy of an answer, so you don't compute it again |
| **Build** | Turning source code into something runnable (a `.jar`, a Docker image) |
| **Artifact** | The versioned output of a build, e.g. `app-1.4.2.jar` |
| **Replica** | A copy of a database that follows the main one |
| **Migration** | A versioned script that changes the database schema |

> 💡 **Tip:** You need a Linux machine to practise. Any of these works: an Ubuntu VM (VirtualBox / Multipass), WSL2 on Windows, a free cloud VM, or Docker Desktop. All commands in this guide assume Ubuntu/Debian unless stated.

---

## 2. How a Web Request Works

**What it is:** The journey of one click, from the browser to the database and back.

**Why DevOps people care:** When something breaks, you debug it **hop by hop**. If you know the hops, you know where to look.

![Request flow](images/01-request-flow.png)

1. **DNS lookup** - the browser asks "what is the IP of `shop.example.com`?" and gets `203.0.113.10`.
2. **TCP + TLS** - the browser connects to port `443` and does the TLS handshake (section 11).
3. **HTTP request** - `GET /products HTTP/1.1` with headers like `Host: shop.example.com`.
4. **Web server** - Nginx receives it, serves static files itself, or forwards to the app.
5. **App server** - your code runs and queries the database.
6. **Database** - returns rows.
7. **Response** - the app builds JSON/HTML, Nginx sends it back with a **status code**.

### 2.1 Status codes you must know

| Code | Meaning | Usually means for DevOps |
|------|---------|--------------------------|
| `200` | OK | All good |
| `301` / `302` | Redirect (permanent / temporary) | HTTP -> HTTPS redirect, moved page |
| `304` | Not Modified | Browser cache is still valid |
| `400` | Bad Request | Client sent garbage |
| `401` / `403` | Not logged in / Forbidden | Auth problem, or file permissions on the server |
| `404` | Not Found | Wrong path, wrong `root`, missing file |
| `413` | Payload Too Large | Raise `client_max_body_size` in Nginx |
| `500` | Internal Server Error | Bug in the app - check app logs |
| `502` | Bad Gateway | **Proxy can't reach the app** (app down, wrong port) |
| `503` | Service Unavailable | App overloaded, or all backends unhealthy |
| `504` | Gateway Timeout | App too slow; proxy gave up waiting |

### 2.2 Try it

```bash
# See every hop: DNS, connect, TLS, headers
curl -v https://example.com

# Only the response headers
curl -I https://example.com

# Timing breakdown
curl -o /dev/null -s -w "dns:%{time_namelookup} connect:%{time_connect} tls:%{time_appconnect} total:%{time_total}\n" https://example.com

# DNS only
dig +short example.com        # or: nslookup example.com
```

---

## 3. Web Server vs Application Server

**What it is:** Two different jobs. The **web server** talks to the internet. The **application server** runs your code.

**Why DevOps people care:** Almost every production setup puts a web server **in front of** the app. You need to know who does what to configure (and debug) it.

![Web server vs app server](images/02-web-vs-app-server.png)

| Language | Typical app server | Listens on |
|----------|-------------------|------------|
| Java | Tomcat, Jetty, Spring Boot (embedded Tomcat) | `8080` |
| Node.js | Node itself (`node server.js`), PM2 to manage it | `3000` |
| Python | Gunicorn, uWSGI, Uvicorn (FastAPI) | `8000` / `5000` |
| PHP | PHP-FPM | `9000` or a Unix socket |
| Ruby | Puma | `3000` |

**Why not expose the app server directly?** Because the web server is much better at TLS, static files, slow clients, compression, rate limiting and spreading load across many app instances.

---

## 4. Install Nginx and First Commands

**What it is:** Nginx (say "engine-x") is the most widely used web server and reverse proxy in DevOps. It is also the engine behind the popular Kubernetes **Ingress NGINX** controller.

**Why DevOps people care:** You will install it, configure it, reload it and read its logs constantly.

```bash
sudo apt update
sudo apt install -y nginx

sudo systemctl status nginx        # is it running?
sudo systemctl enable --now nginx  # start now + on boot
curl -I http://localhost           # Server: nginx

nginx -v                           # version
sudo nginx -t                      # TEST the config (always before reload!)
sudo systemctl reload nginx        # apply config with zero downtime
sudo systemctl restart nginx       # full restart (drops connections)
```

### 4.1 Where things live (Ubuntu/Debian)

| Path | What it is |
|------|-----------|
| `/etc/nginx/nginx.conf` | Main config file |
| `/etc/nginx/conf.d/*.conf` | Extra configs, included automatically |
| `/etc/nginx/sites-available/` | Site configs (Debian style) |
| `/etc/nginx/sites-enabled/` | Symlinks to the sites that are ON |
| `/var/www/html/` | Default website folder |
| `/var/log/nginx/access.log` | Every request |
| `/var/log/nginx/error.log` | Errors - **check this first when something breaks** |

```bash
# Enable a Debian-style site
sudo ln -s /etc/nginx/sites-available/shop /etc/nginx/sites-enabled/shop
sudo nginx -t && sudo systemctl reload nginx

# Watch logs live
sudo tail -f /var/log/nginx/access.log /var/log/nginx/error.log
```

### 4.2 Run Nginx with Docker instead

```bash
docker run -d --name web -p 8080:80 nginx:1.27-alpine
curl http://localhost:8080
docker exec -it web nginx -T      # print the full effective config
docker rm -f web
```

> ⚠️ **Rule:** `nginx -t` before **every** reload. A typo in the config + `restart` = the whole site is down. A typo + `reload` = Nginx refuses the new config and keeps the old one running.

---

## 5. How Nginx Works Inside

**What it is:** Nginx runs one **master** process and a few **worker** processes. Each worker uses an **event loop** to handle thousands of connections at once, instead of one thread per connection.

**Why DevOps people care:** This is why Nginx uses so little memory under heavy load, and why `reload` is safe.

![Nginx architecture](images/03-nginx-architecture.png)

```bash
ps -ef | grep nginx
# root   1234  ... nginx: master process /usr/sbin/nginx
# nginx  1235  ... nginx: worker process
# nginx  1236  ... nginx: worker process
```

| Setting | Meaning |
|---------|---------|
| `worker_processes auto;` | One worker per CPU core |
| `worker_connections 1024;` | Max connections per worker |
| Max clients (roughly) | `worker_processes x worker_connections` (halve it when proxying - each client uses 2 connections) |

---

## 6. Nginx Configuration Structure

**What it is:** The config is made of **directives** (`name value;`) grouped in **blocks** called contexts: `main`, `events`, `http`, `server`, `location`, `upstream`.

**Why DevOps people care:** 90% of Nginx problems are a directive in the wrong block, a missing `;`, or a block that never matches.

![Nginx config structure](images/04-nginx-config-structure.png)

A full working example is in [`examples/nginx/nginx.conf`](examples/nginx/nginx.conf). The shape:

```nginx
user nginx;
worker_processes auto;                 # main context

events {
    worker_connections 1024;
}

http {
    include mime.types;
    gzip on;                           # applies to every server below

    upstream app { server 127.0.0.1:3000; }

    server {                           # one website
        listen 80;
        server_name example.com;

        location / {                   # one URL path
            root /var/www/example;
        }
        location /api/ {
            proxy_pass http://app;
        }
    }
}
```

**Inheritance:** a directive set in `http {}` applies to every `server {}` and `location {}` inside it, unless they override it.

### 6.1 Try it: your first website

```bash
sudo mkdir -p /var/www/example
echo "<h1>Hello from Nginx</h1>" | sudo tee /var/www/example/index.html
sudo cp examples/nginx/static-site.conf /etc/nginx/conf.d/
sudo nginx -t && sudo systemctl reload nginx
curl -H "Host: example.local" http://localhost/
```

---

## 7. Location Blocks

**What it is:** `location` blocks decide what to do with each URL path.

**Why DevOps people care:** "Why does `/api` go to the wrong place?" is always a location-matching question.

| Syntax | Type | Example |
|--------|------|---------|
| `location = /health` | Exact match | Only `/health` |
| `location ^~ /static/` | Prefix, **stop** if it matches (skip regex) | `/static/app.js` |
| `location ~ \.php$` | Regex, case-sensitive | `/index.php` |
| `location ~* \.(jpg\|png)$` | Regex, case-insensitive | `/LOGO.PNG` |
| `location /` | Prefix (catch-all) | Everything else |

![Location matching](images/05-location-matching.png)

### 7.1 `root` vs `alias` (classic trap)

```nginx
location /static/ {
    root /var/www/app;        # /static/a.css -> /var/www/app/static/a.css  (path APPENDED)
}
location /static/ {
    alias /var/www/assets/;   # /static/a.css -> /var/www/assets/a.css      (path REPLACED)
}
```

### 7.2 `proxy_pass` trailing slash (second classic trap)

```nginx
location /api/ { proxy_pass http://app:5000;  }   # /api/users -> app:5000/api/users
location /api/ { proxy_pass http://app:5000/; }   # /api/users -> app:5000/users
```

---

## 8. Virtual Hosts (Server Blocks)

**What it is:** Hosting **many websites on one server and one IP**. Nginx reads the `Host` header of each request and picks the `server {}` block whose `server_name` matches.

**Why DevOps people care:** One cheap VM can serve `shop`, `blog` and `api` sub-domains. It is also exactly how Kubernetes Ingress routes by hostname.

![Virtual hosts](images/06-virtual-hosts.png)

See [`examples/nginx/virtual-hosts.conf`](examples/nginx/virtual-hosts.conf):

```nginx
server {
    listen 80 default_server;   # requests matching no name land here
    server_name _;
    return 444;
}
server {
    listen 80;
    server_name shop.example.local;
    root /var/www/shop;
}
server {
    listen 80;
    server_name blog.example.local;
    root /var/www/blog;
}
```

### 8.1 Try it

```bash
sudo mkdir -p /var/www/shop /var/www/blog
echo "SHOP" | sudo tee /var/www/shop/index.html
echo "BLOG" | sudo tee /var/www/blog/index.html
sudo cp examples/nginx/virtual-hosts.conf /etc/nginx/conf.d/
sudo nginx -t && sudo systemctl reload nginx

curl -H "Host: shop.example.local" http://localhost   # SHOP
curl -H "Host: blog.example.local" http://localhost   # BLOG
curl -H "Host: random.com" http://localhost           # connection closed (444)
```

> 💡 To open them in a browser, add `127.0.0.1 shop.example.local blog.example.local` to `/etc/hosts` (Windows: `C:\Windows\System32\drivers\etc\hosts`).

---

## 9. Reverse Proxy

**What it is:** A server that receives client requests and **forwards them to backend servers**, then returns the backend's answer. The client never talks to the backend directly.

**Why DevOps people care:** It is the most common Nginx job in production: one public entry point, TLS in one place, apps hidden on a private network.

![Forward vs reverse proxy](images/07-forward-vs-reverse-proxy.png)

| | Forward proxy | Reverse proxy |
|--|---------------|---------------|
| Acts for | The **clients** | The **servers** |
| Who knows about it | The client is configured to use it | The client has no idea |
| Examples | Squid, corporate proxy | Nginx, HAProxy, Caddy, AWS ALB |
| Used for | Filtering, outbound caching, hiding clients | TLS, load balancing, caching, security |

### 9.1 The headers you must forward

![Reverse proxy headers](images/08-reverse-proxy-headers.png)

```nginx
location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Full file: [`examples/nginx/reverse-proxy.conf`](examples/nginx/reverse-proxy.conf) (also covers WebSockets and timeouts).

### 9.2 Try it with the sample app

```bash
cd examples/build/node
PORT=3000 node server.js &           # the app, listening on 3000
curl http://localhost:3000           # direct

sudo cp ../../nginx/reverse-proxy.conf /etc/nginx/conf.d/
sudo nginx -t && sudo systemctl reload nginx
curl -H "Host: app.example.local" http://localhost   # through Nginx: see clientIp + forwardedProto

kill %1                               # stop the app...
curl -I -H "Host: app.example.local" http://localhost   # ...502 Bad Gateway. Now you know why.
```

---

## 10. Load Balancing

**What it is:** Spreading requests across **several backend servers** so no single one is overloaded, and so one can die without users noticing.

**Why DevOps people care:** It gives you **scalability** (add servers) and **high availability** (survive failures), and makes zero-downtime deploys possible (drain one server at a time).

![Load balancing algorithms](images/09-load-balancing.png)

```nginx
upstream app_backend {
    least_conn;                                   # algorithm (default: round robin)
    server 10.0.0.11:8080 weight=3;
    server 10.0.0.12:8080 max_fails=3 fail_timeout=30s;
    server 10.0.0.14:8080 backup;
}
server {
    listen 80;
    location / { proxy_pass http://app_backend; }
}
```

### 10.1 Layer 4 vs Layer 7

| | Layer 4 (TCP/UDP) | Layer 7 (HTTP) |
|--|-------------------|----------------|
| Sees | IP + port only | URL, headers, cookies |
| Can route by path / host | No | Yes |
| Speed | Faster | Slightly more work |
| Examples | AWS NLB, HAProxy `mode tcp`, Nginx `stream {}` | AWS ALB, Nginx `http {}`, HAProxy `mode http` |
| Typical use | Databases, MQTT, raw TCP | Websites and APIs |

### 10.2 Health checks

- **Passive** (open-source Nginx): after `max_fails` errors, the server is skipped for `fail_timeout`.
- **Active** (HAProxy, Nginx Plus, cloud LBs): the LB calls `/health` every few seconds and removes failing servers **before** users hit them.

### 10.3 Sticky sessions

If an app keeps logins **in memory**, a user must always hit the same server (`ip_hash` or a cookie). Better fix: store sessions in **Redis** so any server can answer (12-factor, section 29).

> 🧪 **Hands-on:** the full Docker lab is in [`examples/lab-load-balancer/`](examples/lab-load-balancer/) - 3 apps + Nginx, round robin, failover, `ip_hash`.

---

## 11. SSL/TLS and HTTPS

**What it is:** **TLS** (the modern name for SSL) encrypts traffic between browser and server and proves the server is who it claims to be, using a **certificate** signed by a trusted **Certificate Authority (CA)**.

**Why DevOps people care:** Browsers warn on plain HTTP, expired certificates take whole sites down, and certificate renewal is a classic on-call incident.

![TLS handshake](images/10-tls-handshake.png)

### 11.1 Words to know

| Word | Meaning |
|------|---------|
| **Certificate** (`.crt` / `.pem`) | Public file: domain name + public key + CA signature |
| **Private key** (`.key`) | Secret. Never commit it, never share it. `chmod 600` |
| **CA** | Trusted signer: Let's Encrypt (free), DigiCert, AWS ACM... |
| **Chain / fullchain** | Your cert + intermediate certs. Nginx needs the **fullchain** |
| **SNI** | Client sends the hostname in the handshake, so one IP can serve many certs |
| **TLS termination** | Decrypt at the proxy, send plain HTTP to apps on a private network |
| **HSTS** | Header telling browsers "only ever use HTTPS for this site" |

![SSL termination](images/11-ssl-termination.png)

### 11.2 Free certificates with Let's Encrypt

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d shop.example.com -d www.shop.example.com
sudo certbot renew --dry-run          # renewal test (a systemd timer renews automatically)
```

The finished config looks like [`examples/nginx/ssl.conf`](examples/nginx/ssl.conf): port 80 redirects to 443, TLS 1.2/1.3 only, HSTS.

### 11.3 Try it locally with a self-signed certificate

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout selfsigned.key -out selfsigned.crt -subj "/CN=localhost"

# Inspect any certificate
openssl x509 -in selfsigned.crt -noout -subject -issuer -dates

# Check a real site's certificate and expiry
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null \
  | openssl x509 -noout -dates -subject
```

> ⚠️ Self-signed certificates are for labs only. Browsers will warn because no trusted CA signed them.

---

## 12. Apache HTTPD

**What it is:** The original open-source web server (since 1995). Very flexible, with hundreds of modules.

**Why DevOps people care:** Lots of existing systems (WordPress, PHP apps, enterprise intranets, shared hosting) still run on Apache. You will meet it.

| | Apache | Nginx |
|--|--------|-------|
| Model | Process/thread per connection (MPM prefork / worker / **event**) | Event loop |
| Per-folder config | `.htaccess` files (convenient, slower) | No - central config only |
| PHP | `mod_php` in-process, or PHP-FPM | PHP-FPM only |
| Static files at scale | Good | Excellent |

```bash
sudo apt install -y apache2
sudo a2enmod proxy proxy_http ssl headers rewrite   # enable modules
sudo a2ensite shop                                  # enable a site
sudo apachectl configtest                           # like nginx -t
sudo systemctl reload apache2
```

Example virtual host + reverse proxy + load balancer: [`examples/apache/vhost.conf`](examples/apache/vhost.conf).

| Debian/Ubuntu path | What it is |
|--------------------|-----------|
| `/etc/apache2/apache2.conf` | Main config |
| `/etc/apache2/sites-available/` | Site configs |
| `/var/log/apache2/` | Logs |

> ℹ️ On RHEL/CentOS/Amazon Linux the package is `httpd`, configs are in `/etc/httpd/`, and there is no `a2ensite`.

---

## 13. HAProxy

**What it is:** A dedicated, extremely fast **load balancer and proxy** for TCP (Layer 4) and HTTP (Layer 7). It does not serve files - it only forwards.

**Why DevOps people care:** It has the best health checks, detailed stats and fine-grained routing. Used in front of web farms, databases and Kubernetes API servers.

The config has four main parts:

| Section | Purpose |
|---------|---------|
| `global` | Process-wide settings (logging, max connections) |
| `defaults` | Default timeouts and mode for everything below |
| `frontend` | What HAProxy **listens** on, plus ACL routing rules |
| `backend` | Pools of servers, balance algorithm, health checks |

```haproxy
frontend http_in
    bind *:80
    acl is_api path_beg /api
    use_backend api_servers if is_api
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk GET /health
    server web1 10.0.0.11:8080 check
    server web2 10.0.0.12:8080 check
```

Full file with stats page and a TCP example: [`examples/haproxy/haproxy.cfg`](examples/haproxy/haproxy.cfg).

```bash
sudo apt install -y haproxy
haproxy -c -f /etc/haproxy/haproxy.cfg     # validate
sudo systemctl reload haproxy
# Stats dashboard: http://<server>:8404/stats
```

---

## 14. Caddy

**What it is:** A modern web server written in Go whose headline feature is **automatic HTTPS**: point a domain at it and it gets and renews Let's Encrypt certificates on its own.

**Why DevOps people care:** For small services, internal tools and side projects, it removes all certificate work. The config is tiny.

```caddy
app.example.com {
    reverse_proxy 10.0.0.11:8080 10.0.0.12:8080
}
```

That is the whole config: HTTPS, HTTP->HTTPS redirect, HTTP/2 and load balancing. More in [`examples/caddy/Caddyfile`](examples/caddy/Caddyfile).

```bash
docker run -d -p 8443:8443 -v $PWD/examples/caddy/Caddyfile:/etc/caddy/Caddyfile caddy:2
curl -k https://localhost:8443          # "Hello from Caddy"
```

---

## 15. Choosing a Web Server

![Web server comparison](images/12-web-server-comparison.png)

| Need | Pick |
|------|------|
| General web server + reverse proxy (default answer) | **Nginx** |
| Legacy PHP app, `.htaccess`, existing Apache estate | **Apache** |
| Heavy load balancing, TCP services, advanced health checks | **HAProxy** |
| Small service, want HTTPS with zero effort | **Caddy** |
| On AWS and don't want to run servers | **ALB** (L7) / **NLB** (L4) |
| Inside Kubernetes | **Ingress controller** (ingress-nginx, Traefik, HAProxy) or Gateway API |

---

# PART 2: Caching (Make It Fast)

---

## 16. Caching Basics

**What it is:** Saving a copy of a response so the next identical request is answered from the copy instead of doing the work again.

**Why DevOps people care:** Caching is the cheapest performance win there is. It cuts server costs, database load and response times - and **stale caches** are a classic source of "I deployed but I still see the old version".

![Caching layers](images/13-caching-layers.png)

| Term | Meaning |
|------|---------|
| **Hit** | Answer found in cache |
| **Miss** | Not in cache - go to the next layer, then store the answer |
| **TTL** | Time To Live - how long an entry stays fresh |
| **Hit ratio** | hits / (hits + misses). Higher = better |
| **Invalidation / purge** | Deleting cached entries when content changes |
| **Cache key** | What makes two requests "the same" (usually host + URL, sometimes headers) |

> 💬 "There are only two hard things in Computer Science: cache invalidation and naming things." - Phil Karlton

### 16.1 Nginx can cache too

```nginx
http {
    proxy_cache_path /var/cache/nginx keys_zone=appcache:10m max_size=1g inactive=60m;
    server {
        location / {
            proxy_cache appcache;
            proxy_cache_valid 200 10m;
            add_header X-Cache-Status $upstream_cache_status;   # HIT / MISS / EXPIRED
            proxy_pass http://app_backend;
        }
    }
}
```

---

## 17. HTTP Cache Headers

**What it is:** Response headers that tell **every** cache (browser, CDN, Varnish, Nginx) what it may store and for how long.

**Why DevOps people care:** Wrong headers either make caching useless or, worse, cache one user's private data and show it to another user.

![Cache headers](images/16-cache-headers.png)

| Header | Meaning |
|--------|---------|
| `Cache-Control: max-age=600` | Fresh for 600 seconds |
| `s-maxage=600` | Same, but only for shared caches (CDN, Varnish) |
| `public` / `private` | May shared caches store it? `private` = browser only |
| `no-cache` | Store it, but re-validate with the server every time |
| `no-store` | Never store it anywhere |
| `immutable` | Will never change (use with hashed file names) |
| `ETag` / `If-None-Match` | Version fingerprint; server returns `304 Not Modified` if unchanged |
| `Vary: Accept-Encoding` | Cache separate copies per header value |

```bash
curl -I https://www.google.com | grep -i -E "cache-control|etag|age|expires"
```

**Golden pattern:** build tools put a hash in static file names (`app.3f9a1c.js`) -> cache them for a year with `immutable`. Keep `index.html` on a short TTL or `no-cache` so it always points to the latest hashes. Deploys then "invalidate" automatically.

---

## 18. Varnish

**What it is:** A dedicated HTTP **cache** (an "HTTP accelerator") that sits in front of your app and keeps responses in RAM. It is programmed with **VCL** (Varnish Configuration Language).

**Why DevOps people care:** It can take a busy content site from hundreds to tens of thousands of requests per second with the same backend. Common in front of WordPress, Drupal, Magento and news sites.

![Varnish flow](images/14-varnish-flow.png)

| VCL subroutine | Runs when | Typical use |
|----------------|-----------|-------------|
| `vcl_recv` | Request arrives | Decide pass/cache, clean URLs, strip cookies, handle PURGE |
| `vcl_hash` | Building the cache key | Add headers to the key |
| `vcl_hit` / `vcl_miss` | After lookup | Rarely changed |
| `vcl_backend_response` | Backend answered | Set TTL, grace |
| `vcl_deliver` | Before sending to client | Add debug headers (`X-Cache: HIT`) |

Example: [`examples/varnish/default.vcl`](examples/varnish/default.vcl)

```bash
docker run -d --name varnish -p 6081:80 \
  -v $PWD/examples/varnish/default.vcl:/etc/varnish/default.vcl:ro varnish:7.5
# (point .host in the VCL at a running backend first, e.g. host.docker.internal:3000)

curl -I http://localhost:6081/    # X-Cache: MISS
curl -I http://localhost:6081/    # X-Cache: HIT

varnishstat     # hit/miss counters (inside the container)
varnishlog      # every request, in detail
```

> ⚠️ Varnish **does not speak HTTPS**. The usual chain is `Nginx/HAProxy :443 (TLS) -> Varnish :6081 -> App :8080`.

---

## 19. CDN Concepts: Cloudflare and CloudFront

**What it is:** A **Content Delivery Network** is a worldwide network of cache servers (edge locations / PoPs). Users get content from the nearest edge instead of from your origin server.

**Why DevOps people care:** Faster pages worldwide, much less load on your origin, plus DDoS protection and a WAF in front of your app.

![CDN](images/15-cdn.png)

| Concept | Meaning |
|---------|---------|
| **Origin** | Your real server or S3 bucket |
| **Edge / PoP** | CDN data centre near users |
| **Cache hit ratio** | % served from the edge - aim for 90%+ on static assets |
| **Invalidation / purge** | Tell the CDN to drop cached files after a deploy |
| **TTL** | Controlled by your `Cache-Control` headers (or CDN rules) |
| **Origin shield** | An extra cache layer that protects the origin from many edges missing at once |

| | Cloudflare | Amazon CloudFront |
|--|------------|-------------------|
| How you connect | Move your **DNS** to Cloudflare; orange-cloud = proxied | Create a **distribution**, point a CNAME / Route 53 alias at it |
| Origins | Any server | S3, ALB, EC2, API Gateway, any HTTP server |
| Extras | WAF, DDoS, free TLS, Workers, Zero Trust | AWS WAF, Shield, Lambda@Edge / CloudFront Functions, ACM certs |
| Purge | Dashboard / API "Purge Cache" | `aws cloudfront create-invalidation` |

```bash
# Invalidate everything after a deploy (CloudFront)
aws cloudfront create-invalidation --distribution-id E123ABC --paths "/*"

# Is a site behind a CDN? Look for CDN headers
curl -sI https://www.cloudflare.com | grep -i -E "cf-ray|cf-cache-status|server"
```

> 💡 Classic static-site setup on AWS: **S3** (private bucket) -> **CloudFront** (with Origin Access Control) -> **Route 53** alias -> **ACM** certificate.

---

# PART 3: How Applications Are Built and Run (Ship the App)

---

## 20. From Source Code to Running App

**What it is:** The path code takes: **source -> build -> artifact -> artifact repository -> deploy -> run**.

**Why DevOps people care:** This path **is** the CI/CD pipeline. Every build tool, repository and deploy script you touch is one box on this picture.

![Source to running app](images/17-source-to-running-app.png)

| Word | Meaning |
|------|---------|
| **Dependencies** | Libraries your code uses (downloaded during the build) |
| **Compile** | Turn source into machine/byte code (Java -> `.class`) |
| **Package** | Bundle into one deliverable (`.jar`, `.war`, `.whl`, `.tgz`, Docker image) |
| **Artifact** | That deliverable, with a version: `demo-app-1.4.2.jar` |
| **Lock file** | Exact versions of every dependency (`package-lock.json`, `poetry.lock`, `gradle.lockfile`) |
| **Reproducible build** | Same commit -> same artifact, every time |

> 🏆 **Golden rule: build once, deploy many.** The *same* artifact goes to dev, staging and production. Only **configuration** changes between environments (section 29). Never rebuild for production.

---

## 21. Build Tools Overview

**What it is:** Programs that automate getting dependencies, compiling, testing and packaging.

**Why DevOps people care:** CI pipelines are mostly "run the build tool". When a pipeline fails, you read its output.

![Build tools](images/18-build-tools.png)

All sample build files are in [`examples/build/`](examples/build/).

---

## 22. Maven

**What it is:** The classic Java build tool. Configured with **`pom.xml`** (Project Object Model). Convention over configuration: code in `src/main/java`, tests in `src/test/java`, output in `target/`.

**Why DevOps people care:** Most enterprise Java (Spring Boot) projects use it, and it publishes to Nexus/Artifactory.

![Maven lifecycle](images/19-maven-lifecycle.png)

### 22.1 Key ideas

| Idea | Meaning |
|------|---------|
| **GAV** | `groupId:artifactId:version` - the unique address, e.g. `com.example:demo-app:1.0.0` |
| **SNAPSHOT** | `1.1.0-SNAPSHOT` = work in progress, can be overwritten. Releases (`1.1.0`) are immutable |
| **Scope** | `compile` (default), `test`, `provided`, `runtime` |
| **Local repo** | `~/.m2/repository` - cache of everything downloaded |
| **settings.xml** | `~/.m2/settings.xml` - mirrors and **credentials** (never in the repo) |

```bash
mvn -v
mvn clean package            # -> target/demo-app-1.0.0.jar
mvn test
mvn clean verify             # + integration tests
mvn dependency:tree          # who pulled in which library?
mvn -B -ntp clean package    # CI mode: batch, no download progress spam
mvn deploy                   # upload to Nexus
java -jar target/demo-app-1.0.0.jar
```

Sample files: [`pom.xml`](examples/build/maven/pom.xml), [`settings.xml`](examples/build/maven/settings.xml).

> 💡 Many projects include the **Maven Wrapper** (`./mvnw`) so everyone uses the same Maven version without installing it.

---

## 23. Gradle

**What it is:** A faster, more flexible build tool for Java, Kotlin and **Android**. Config is code: `build.gradle` (Groovy) or `build.gradle.kts` (Kotlin).

**Why DevOps people care:** Incremental builds + build cache make CI much faster on large projects. All Android apps use it.

```bash
./gradlew --version          # ALWAYS use the wrapper, not a global "gradle"
./gradlew clean build        # compile + test + jar  -> build/libs/
./gradlew test
./gradlew dependencies
./gradlew publish            # upload to Nexus/Artifactory
./gradlew tasks              # list available tasks
```

| Maven | Gradle |
|-------|--------|
| `pom.xml` (XML) | `build.gradle(.kts)` (code) |
| Fixed lifecycle phases | Graph of tasks |
| `target/` | `build/` |
| `mvn package` | `./gradlew build` |
| Simple, predictable | Faster, more flexible |

Sample: [`build.gradle.kts`](examples/build/gradle/build.gradle.kts).

---

## 24. npm

**What it is:** The package manager and script runner for **Node.js / JavaScript**. Configured with `package.json`; exact versions locked in `package-lock.json`.

**Why DevOps people care:** Every frontend (React, Angular, Vue) and Node backend is built with npm (or its cousins yarn / pnpm).

```bash
npm init -y                  # new package.json
npm install express          # add a dependency
npm install -D jest          # dev-only dependency
npm ci                       # CI: clean install EXACTLY from package-lock.json
npm run build                # run the "build" script in package.json
npm test
npm audit                    # known vulnerabilities
npm outdated
```

| `npm install` | `npm ci` |
|---------------|----------|
| May update the lock file | Never changes the lock file - fails if it doesn't match |
| For developers | **For CI/CD pipelines** (reproducible, faster) |

> ⚠️ Always commit `package-lock.json`. Never commit `node_modules/`.

Sample app: [`package.json`](examples/build/node/package.json), [`server.js`](examples/build/node/server.js), [`Dockerfile`](examples/build/node/Dockerfile).

```bash
cd examples/build/node
npm start                                     # http://localhost:3000
docker build -t demo-app:1.0.0 .
docker run --rm -p 3000:3000 -e APP_NAME=blue demo-app:1.0.0
```

---

## 25. pip

**What it is:** Python's package installer. Dependencies are listed in `requirements.txt` (or `pyproject.toml`). Always used inside a **virtual environment** so projects don't clash.

**Why DevOps people care:** Python is everywhere in DevOps: Ansible, automation scripts, AWS CLI, Flask/Django/FastAPI apps.

```bash
python3 -m venv .venv
source .venv/bin/activate              # Windows: .venv\Scripts\activate
pip install -r requirements.txt
pip freeze > requirements.txt          # pin exact versions
pip list --outdated
python -m build                        # -> dist/*.whl  (package for upload)
deactivate
```

Run a Python web app in production with an app server, not `python app.py`:

```bash
gunicorn --workers 4 --bind 0.0.0.0:8000 app:app      # then Nginx in front
```

Samples: [`requirements.txt`](examples/build/python/requirements.txt), [`pyproject.toml`](examples/build/python/pyproject.toml).

> 💡 Newer tools like **Poetry** and **uv** add lock files and speed, but `pip` + `venv` is what you must know first.

---

## 26. Make

**What it is:** A 1970s build tool that is still everywhere. A `Makefile` defines **targets** with commands and dependencies between them.

**Why DevOps people care:** Teams wrap every tool behind `make` so humans and CI run the **same** short commands (`make test`, `make docker`, `make deploy`), whatever the language.

```makefile
build: test               ## "build" depends on "test"
	@echo "Building..."     # <- this line MUST start with a TAB
```

```bash
cd examples/build
make help        # list targets
make test        # runs install first (dependency)
make build
make docker VERSION=1.2.3
```

Sample: [`examples/build/Makefile`](examples/build/Makefile).

> ⚠️ The #1 Make error: `Makefile:5: *** missing separator.` = you used spaces instead of a **tab**.

---

## 27. Artifact Repositories: Nexus and Artifactory

**What it is:** A server that stores and serves **build artifacts and dependencies**: Maven jars, npm packages, Python wheels, Docker images, Helm charts. **Sonatype Nexus** and **JFrog Artifactory** are the two big ones.

**Why DevOps people care:** It is the hand-off point between CI (build) and CD (deploy), and it protects you from the internet: if Maven Central or npmjs is slow, down, or a package gets deleted, your builds still work.

![Artifact repository](images/20-artifact-repository.png)

| Repository type | What it does |
|-----------------|-------------|
| **Hosted** (Artifactory: *local*) | Stores **your** artifacts: `maven-releases`, `maven-snapshots` |
| **Proxy** (Artifactory: *remote*) | Caches a public registry (Maven Central, npmjs, PyPI, Docker Hub) |
| **Group** (Artifactory: *virtual*) | One URL that combines several repos - what clients use |

### 27.1 Try it: run Nexus locally

```bash
docker run -d --name nexus -p 8081:8081 sonatype/nexus3
# wait ~2 minutes, then open http://localhost:8081
docker exec nexus cat /nexus-data/admin.password     # first login: admin / this password
```

Then point tools at it:

```bash
# Maven: mirror in ~/.m2/settings.xml (see examples/build/maven/settings.xml)
# npm
npm config set registry http://localhost:8081/repository/npm-group/
# pip
pip install --index-url http://localhost:8081/repository/pypi-group/simple flask
# Docker
docker login localhost:8082 && docker push localhost:8082/demo-app:1.0.0
```

| | Nexus | Artifactory |
|--|-------|------------|
| Free edition | Nexus Repository Community Edition | Artifactory OSS / JFrog Container Registry (limited formats) |
| Strong at | Simple, popular for Maven/npm | Every format, enterprise features, JFrog Xray security scanning |

> 🔐 Cloud alternatives: AWS CodeArtifact + ECR, GitHub Packages, GitLab Package Registry, Azure Artifacts.

---

## 28. Monolith vs Microservices

**What it is:** Two ways to structure an application. A **monolith** is one codebase deployed as one unit. **Microservices** split it into small services that each own one business capability and their own data, talking over the network (HTTP/gRPC or queues).

**Why DevOps people care:** The architecture decides **everything** about deployment: number of pipelines, how you scale, monitoring, networking, and how much infrastructure you need.

![Monolith vs microservices](images/21-monolith-vs-microservices.png)

| | Monolith | Microservices |
|--|----------|---------------|
| Deploy | One artifact, one pipeline | Many artifacts, many pipelines |
| Scale | Whole app (scale out copies) | Each service independently |
| Failure | One bug can take everything down | Failures can be isolated (with timeouts, circuit breakers) |
| Data | One shared database | Database per service |
| Team fit | Small team | Many teams, each owning services |
| Ops complexity | Low | High: containers, Kubernetes, service discovery, distributed tracing, API gateway |
| Debugging | Stack trace in one process | Following a request across services (tracing: Jaeger, OpenTelemetry) |

**What you will see in real life:** start with a **modular monolith**, split out services only when a part needs independent scaling or a separate team. Microservices are a solution to an organisational scaling problem, not a default.

---

## 29. The 12-Factor App

**What it is:** Twelve rules (from Heroku engineers, [12factor.net](https://12factor.net)) for building apps that are easy to deploy, scale and run on any cloud. Containers and Kubernetes assume these rules.

**Why DevOps people care:** When an app follows them, deploying it is easy. When it doesn't, you get "works on my machine", lost files, and hard-coded passwords.

![12-factor app](images/22-twelve-factor.png)

| # | Factor | In practice (DevOps view) |
|---|--------|---------------------------|
| I | **Codebase** | One Git repo per app; dev/staging/prod are deploys of the same repo |
| II | **Dependencies** | Declared in `pom.xml` / `package.json` / `requirements.txt` + lock files. Never rely on system packages |
| III | **Config** | DB URLs, keys, feature flags in **environment variables** - never in code. See [`.env.example`](examples/twelve-factor/.env.example) |
| IV | **Backing services** | DB, Redis, queue are attached by URL - swap local Postgres for RDS by changing one variable |
| V | **Build, release, run** | Build = artifact. Release = artifact + config. Run = start it. Never edit code on the server |
| VI | **Processes** | Stateless. Sessions in Redis, files in S3 - not local disk or memory |
| VII | **Port binding** | The app serves HTTP on its own port (`PORT=3000`); Nginx/LB sits in front |
| VIII | **Concurrency** | Scale by running more processes/containers (horizontal), not a bigger box |
| IX | **Disposability** | Start fast, stop gracefully on `SIGTERM` - containers get killed all the time |
| X | **Dev/prod parity** | Same Postgres version in dev and prod (Docker Compose helps) |
| XI | **Logs** | Write to **stdout**; the platform (Docker, K8s, CloudWatch, ELK) collects them |
| XII | **Admin processes** | Migrations, one-off scripts run as separate processes with the same code + config |

Our sample [`server.js`](examples/build/node/server.js) shows factors III, VII, IX and XI in about 40 lines.

```bash
cd examples/build/node
PORT=4000 APP_NAME=green node server.js     # same code, different config
```

---

# PART 4: Databases at DevOps Level (Keep Data Safe)

---

> 🧰 **Playground:** every database in this part runs locally from [`examples/databases/docker-compose.yml`](examples/databases/docker-compose.yml).
> Start only what you need, e.g. `docker compose up -d postgres redis`.

## 30. SQL vs NoSQL

**What it is:** **SQL (relational)** databases store data in tables with a fixed schema and relationships. **NoSQL** databases use other models (documents, key-value, wide-column, graph) that trade some features for flexibility and horizontal scale.

**Why DevOps people care:** You don't usually design the schema, but you **run** these systems: install, secure, back up, replicate, monitor, upgrade. Each type fails and scales differently.

![SQL vs NoSQL](images/23-sql-vs-nosql.png)

| | SQL | NoSQL |
|--|-----|-------|
| Examples | MySQL, PostgreSQL, MariaDB, SQL Server, Oracle | MongoDB, Redis, Cassandra, DynamoDB, Neo4j |
| Schema | Fixed, changed via migrations | Flexible |
| Transactions | Full **ACID** | Varies; often eventual consistency (**BASE**) |
| Scaling | Vertical + read replicas | Horizontal (sharding / partitioning) |
| Query | SQL with JOINs | API / query language per product |

**ACID** = Atomicity (all or nothing), Consistency (rules always hold), Isolation (transactions don't see each other's half-done work), Durability (committed = survives a crash).

**CAP theorem** (for distributed databases): during a network **P**artition you must choose **C**onsistency (refuse some requests) or **A**vailability (answer, maybe with stale data).

---

## 31. MySQL and PostgreSQL Basics

**What it is:** The two most popular open-source relational databases. **MySQL** (and its fork MariaDB) is simple and everywhere (WordPress, LAMP stack). **PostgreSQL** is feature-rich and standards-focused (JSONB, extensions like PostGIS, strong consistency).

**Why DevOps people care:** You will create databases and users, grant permissions, check connections, and find slow queries - often at 2 AM.

### 31.1 Connect and look around

```bash
docker compose -f examples/databases/docker-compose.yml up -d mysql postgres
```

| Task | MySQL | PostgreSQL |
|------|-------|------------|
| Connect | `mysql -h 127.0.0.1 -u app -p appdb` | `psql -h localhost -U app -d appdb` |
| In Docker | `docker compose exec mysql mysql -u root -p` | `docker compose exec postgres psql -U app appdb` |
| List databases | `SHOW DATABASES;` | `\l` |
| Use a database | `USE appdb;` | `\c appdb` |
| List tables | `SHOW TABLES;` | `\dt` |
| Describe table | `DESCRIBE users;` | `\d users` |
| Who is connected | `SHOW PROCESSLIST;` | `SELECT * FROM pg_stat_activity;` |
| Quit | `exit` | `\q` |
| Default port | `3306` | `5432` |
| Main config | `/etc/mysql/my.cnf` | `postgresql.conf` + `pg_hba.conf` (who may connect) |

### 31.2 Create an app user (least privilege)

```sql
-- MySQL
CREATE DATABASE shop;
CREATE USER 'shop_app'@'%' IDENTIFIED BY 'S3cure!pass';
GRANT SELECT, INSERT, UPDATE, DELETE ON shop.* TO 'shop_app'@'%';

-- PostgreSQL
CREATE DATABASE shop;
CREATE USER shop_app WITH PASSWORD 'S3cure!pass';
GRANT CONNECT ON DATABASE shop TO shop_app;
-- then, connected to shop:
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO shop_app;
```

> ⚠️ Apps never connect as `root` / `postgres`. One user per app, only the rights it needs, password from a secret store.

### 31.3 DevOps health checks

```sql
-- PostgreSQL: long-running queries
SELECT pid, now() - query_start AS runtime, state, query
FROM pg_stat_activity WHERE state <> 'idle' ORDER BY runtime DESC;

-- PostgreSQL: database sizes
SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;

-- MySQL: connections vs limit
SHOW STATUS LIKE 'Threads_connected';
SHOW VARIABLES LIKE 'max_connections';

-- Why is this query slow? (both)
EXPLAIN SELECT * FROM orders WHERE user_id = 42;
```

Common production issues: **too many connections** (use a pool like PgBouncer / HikariCP), **disk full**, **missing index**, **long-running transaction holding locks**.

---

## 32. Backups and Restore

**What it is:** Copies of your data you can restore after hardware failure, a bad deploy, a `DELETE` without `WHERE`, or ransomware.

**Why DevOps people care:** It is often **the** DevOps responsibility. And the rule everyone learns the hard way: **a backup you have never restored is not a backup.**

![Backups RPO RTO](images/24-backups-rpo-rto.png)

| Term | Meaning |
|------|---------|
| **RPO** - Recovery Point Objective | How much data you can afford to lose (e.g. "max 5 minutes") |
| **RTO** - Recovery Time Objective | How long you can be down while restoring (e.g. "max 1 hour") |
| **Logical backup** | SQL/JSON export (`mysqldump`, `pg_dump`). Portable, slow for big DBs |
| **Physical backup** | Copy of data files (`pg_basebackup`, Percona XtraBackup, disk snapshots). Fast |
| **PITR** | Point-In-Time Recovery = full backup + replay of binlog (MySQL) / WAL (Postgres) to any second |
| **3-2-1 rule** | 3 copies, 2 different media, 1 off-site |

### 32.1 Commands

```bash
# PostgreSQL
pg_dump -U app -Fc -f appdb.dump appdb            # custom format (compressed, selective restore)
pg_restore -U app -d appdb_restore appdb.dump
pg_dumpall -U postgres > all.sql                  # every DB + roles

# MySQL
mysqldump --single-transaction --routines --triggers appdb | gzip > appdb.sql.gz
gunzip < appdb.sql.gz | mysql appdb_restore

# MongoDB
mongodump --uri="mongodb://root:rootpass@localhost:27017" --out=/backups/mongo
mongorestore --uri="mongodb://root:rootpass@localhost:27017" /backups/mongo
```

Production-style scripts with rotation, verification and S3 upload:

- [`postgres-backup.sh`](examples/databases/backup/postgres-backup.sh)
- [`postgres-restore.sh`](examples/databases/backup/postgres-restore.sh) - restores into a **new** database for testing
- [`mysql-backup.sh`](examples/databases/backup/mysql-backup.sh)

```bash
# Schedule nightly at 02:00
crontab -e
0 2 * * * /opt/scripts/postgres-backup.sh >> /var/log/pg-backup.log 2>&1
```

> ☁️ Managed databases (AWS RDS / Aurora, Cloud SQL, Azure Database) do automated backups + PITR for you - but you still choose retention, test restores and protect snapshots from deletion.

---

## 33. Replication

**What it is:** Keeping copies of a database on other servers, continuously updated. The **primary** accepts writes and streams its change log (MySQL **binlog**, PostgreSQL **WAL**) to **replicas**.

**Why DevOps people care:** Replicas give you **read scaling** (send reports and reads to replicas), **high availability** (promote a replica if the primary dies) and a source for backups without loading the primary.

![Replication](images/25-replication.png)

| Term | Meaning |
|------|---------|
| **Primary / replica** | Older docs say master / slave |
| **Asynchronous** | Primary doesn't wait. Fast, but a crash can lose the last few transactions |
| **Synchronous / semi-sync** | Commit waits for at least one replica. Safer, slower |
| **Replication lag** | How far behind a replica is. Reads from a lagging replica return stale data |
| **Failover** | Promoting a replica to primary (manual, or automatic with Patroni, Orchestrator, RDS Multi-AZ) |
| **Split brain** | Two nodes both think they are primary - the disaster automatic failover tools prevent |

```sql
-- PostgreSQL: on the primary, see replicas and their lag
SELECT client_addr, state, sync_state, replay_lag FROM pg_stat_replication;

-- PostgreSQL: on a replica
SELECT pg_is_in_recovery();          -- true = I am a replica

-- MySQL: on a replica
SHOW REPLICA STATUS\G                -- check Seconds_Behind_Source, *_Running: Yes
```

> ⚠️ **Replication is not a backup.** A `DROP TABLE` on the primary is replicated to every replica within milliseconds. You need both.

---

## 34. MongoDB

**What it is:** A **document database**. Data is stored as JSON-like documents (BSON) in **collections**, with no fixed schema.

**Why DevOps people care:** Popular with Node.js apps (MEAN/MERN stack). You run its **replica sets** (HA) and **sharded clusters** (scale), and its backups.

![NoSQL types](images/26-nosql-types.png)

| SQL | MongoDB |
|-----|---------|
| Database | Database |
| Table | Collection |
| Row | Document |
| Column | Field |
| JOIN | Embedded documents or `$lookup` |

```bash
docker compose -f examples/databases/docker-compose.yml up -d mongo
docker compose -f examples/databases/docker-compose.yml exec mongo mongosh -u root -p rootpass
```

```javascript
use shop
db.users.insertOne({ name: "Kasun", email: "kasun@example.com", tags: ["devops"] })
db.users.find({ tags: "devops" })
db.users.createIndex({ email: 1 }, { unique: true })
db.stats()
rs.status()                 // replica set health (in a replica set)
```

| DevOps concept | Meaning |
|----------------|---------|
| **Replica set** | 1 primary + secondaries (min 3 members) with automatic election |
| **Sharding** | Split a collection across shards by a shard key |
| Port | `27017` |
| Always | Enable auth, never expose 27017 to the internet (many ransomware incidents) |

---

## 35. Redis

**What it is:** An **in-memory key-value store**. Microsecond reads, with data structures (strings, hashes, lists, sets, sorted sets, streams) and optional persistence to disk.

**Why DevOps people care:** It is the default choice for **caching**, **sessions**, **rate limiting**, simple **queues** and leaderboards. It is in almost every architecture.

![Redis cache-aside](images/27-redis-cache-aside.png)

```bash
docker compose -f examples/databases/docker-compose.yml up -d redis
docker compose -f examples/databases/docker-compose.yml exec redis redis-cli
```

```text
SET session:42 "user=kasun" EX 3600    # value with 1h TTL
GET session:42
TTL session:42
INCR page:views                        # atomic counter (rate limiting!)
HSET user:1 name Kasun role devops     # hash
LPUSH jobs "send-email"                # list as a simple queue
KEYS *                                 # NEVER in production (blocks Redis) - use SCAN
INFO memory
INFO stats                             # keyspace_hits / keyspace_misses = hit ratio
```

| DevOps concept | Meaning |
|----------------|---------|
| **Persistence** | **RDB** = periodic snapshots. **AOF** = log of every write. Or none (pure cache) |
| **maxmemory + eviction** | e.g. `allkeys-lru` - drop least-recently-used keys when full |
| **Replication** | Primary + replicas; **Sentinel** for automatic failover |
| **Redis Cluster** | Sharding across nodes (16384 hash slots) |
| Port | `6379` |
| Managed | AWS ElastiCache / MemoryDB, Azure Cache for Redis |
| Note | Redis changed its license in 2024; **Valkey** is the Linux Foundation open-source fork, same commands |

---

## 36. Cassandra

**What it is:** A distributed **wide-column** database with **no primary node**: every node is equal, arranged in a ring. Built for huge write volumes and multi-data-centre setups.

**Why DevOps people care:** Used for time-series, IoT, messaging and activity feeds at massive scale (Netflix, Apple, Discord used it). Operating it means understanding nodes, replication factor and consistency levels.

| Concept | Meaning |
|---------|---------|
| **Masterless ring** | Any node accepts reads/writes; no single point of failure |
| **Keyspace** | Like a database; defines replication |
| **Partition key** | Decides which node stores the row - design tables around your queries |
| **Replication factor (RF)** | Copies of each row, usually `3` |
| **Consistency level** | Per query: `ONE`, `QUORUM`, `ALL`... `QUORUM` reads + writes = strong consistency |
| Port | `9042` (CQL) |
| Tools | `nodetool status`, `cqlsh` |

```bash
docker compose -f examples/databases/docker-compose.yml up -d cassandra   # needs ~1 min to start
docker compose -f examples/databases/docker-compose.yml exec cassandra nodetool status
docker compose -f examples/databases/docker-compose.yml exec cassandra cqlsh
```

```sql
CREATE KEYSPACE iot WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
USE iot;
CREATE TABLE readings (sensor_id text, ts timestamp, temp double, PRIMARY KEY (sensor_id, ts));
INSERT INTO readings (sensor_id, ts, temp) VALUES ('sensor_7', toTimestamp(now()), 21.4);
SELECT * FROM readings WHERE sensor_id = 'sensor_7';
```

---

## 37. Message Queues and RabbitMQ

**What it is:** A **message queue** lets one service (producer) leave a message that another service (consumer) processes later. **RabbitMQ** is a popular message broker that implements AMQP with flexible routing.

**Why DevOps people care:** Queues **decouple** services: if the email service is down, orders still succeed and emails are sent when it comes back. They absorb traffic spikes and enable retries. You'll monitor queue depth and consumers.

![RabbitMQ](images/28-rabbitmq.png)

| Concept | Meaning |
|---------|---------|
| **Producer / consumer** | Sends / receives messages |
| **Exchange** | Receives messages and routes them to queues |
| **Queue** | Buffer that stores messages until consumed |
| **Binding** | Rule linking an exchange to a queue |
| **Exchange types** | `direct` (exact key), `topic` (patterns like `order.*`), `fanout` (all queues), `headers` |
| **ACK** | Consumer confirms success; un-ACKed messages are re-delivered |
| **Dead-letter queue (DLQ)** | Where messages go after failing too many times |
| **Durable / persistent** | Queue and messages survive a broker restart |

```bash
docker compose -f examples/databases/docker-compose.yml up -d rabbitmq
# Management UI: http://localhost:15672   (guest / guest - local only)

docker compose -f examples/databases/docker-compose.yml exec rabbitmq rabbitmqctl list_queues name messages consumers
docker compose -f examples/databases/docker-compose.yml exec rabbitmq rabbitmq-diagnostics status
```

> 📈 The key metric: **queue depth**. If messages keep growing, consumers are too slow or dead - scale them out or fix them.

---

## 38. Kafka Basics

**What it is:** A distributed **event streaming platform**. Unlike a classic queue, Kafka is an **append-only log**: messages are kept for a retention period (e.g. 7 days) even after they are read, so many consumers can read the same data, and replay it.

**Why DevOps people care:** It powers event-driven microservices, log and metrics pipelines, and real-time analytics. You run brokers, size partitions, and watch **consumer lag**.

![Kafka](images/29-kafka.png)

| Concept | Meaning |
|---------|---------|
| **Broker** | One Kafka server. A cluster has several |
| **Topic** | A named stream of events, e.g. `orders` |
| **Partition** | A topic is split into partitions for parallelism. Order is guaranteed **within** a partition |
| **Offset** | Position of a message inside a partition |
| **Producer key** | Same key -> same partition -> ordered for that key |
| **Consumer group** | Consumers sharing the work; each partition goes to one consumer in the group |
| **Consumer lag** | How far behind a group is - the #1 Kafka metric |
| **Replication factor** | Copies of each partition across brokers (production: 3) |
| **KRaft** | Kafka's built-in metadata quorum; replaces ZooKeeper (ZooKeeper removed in Kafka 4.0) |

```bash
docker compose -f examples/databases/docker-compose.yml up -d kafka
K="docker compose -f examples/databases/docker-compose.yml exec kafka /opt/kafka/bin"

$K/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic orders --partitions 3 --replication-factor 1
$K/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic orders

# Terminal 1: produce (type messages, Ctrl+C to stop)
docker compose -f examples/databases/docker-compose.yml exec kafka \
  /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic orders

# Terminal 2: consume from the beginning
docker compose -f examples/databases/docker-compose.yml exec kafka \
  /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic orders --from-beginning --group billing

# Consumer lag per partition
$K/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group billing
```

### 38.1 RabbitMQ or Kafka?

| | RabbitMQ | Kafka |
|--|----------|-------|
| Model | Queue: message deleted after ACK | Log: kept for retention period |
| Strength | Smart routing, task queues, per-message ACK | Massive throughput, replay, many independent readers |
| Ordering | Per queue | Per partition |
| Typical use | Background jobs, RPC, emails, workflows | Event streaming, logs, metrics, CDC, analytics |
| Managed | Amazon MQ, CloudAMQP | Amazon MSK, Confluent Cloud |

---

## 39. Database Migrations: Flyway and Liquibase

**What it is:** **Version control for your database schema.** Every change (create table, add column, add index) is a numbered file in Git. A tool applies the pending ones, in order, exactly once, and records what it did in a history table.

**Why DevOps people care:** Schema changes become part of the **pipeline** instead of someone running SQL by hand in production. Every environment ends up with the exact same schema.

![DB migrations](images/30-db-migrations.png)

### 39.1 Flyway

Files are named `V<version>__<description>.sql` (two underscores):

```text
examples/databases/flyway/sql/
├── V1__create_users.sql
├── V2__create_orders.sql
└── V3__add_orders_user_index.sql
```

```bash
cd examples/databases
docker compose up -d postgres
docker compose --profile migrate run --rm flyway          # applies V1, V2, V3

# What happened?
docker compose exec postgres psql -U app appdb -c "SELECT version, description, success FROM flyway_schema_history;"

# Run it again - nothing to do, already applied
docker compose --profile migrate run --rm flyway
```

| Command | Does |
|---------|------|
| `flyway info` | Shows applied and pending migrations |
| `flyway migrate` | Applies pending migrations |
| `flyway validate` | Checks applied files weren't edited (checksums) |
| `flyway repair` | Fixes the history table after a failed migration |
| `flyway baseline` | Start using Flyway on an existing database |

### 39.2 Liquibase

Changes are **changesets** in a changelog (XML, YAML, JSON or SQL), tracked in the `DATABASECHANGELOG` table, with built-in **rollback** support. See [`changelog.yaml`](examples/databases/liquibase/changelog.yaml).

```bash
liquibase --changelog-file=changelog.yaml --url=jdbc:postgresql://localhost:5432/appdb \
          --username=app --password=$DB_PASSWORD update
liquibase ... status
liquibase ... rollback-count 1
```

| | Flyway | Liquibase |
|--|--------|-----------|
| Format | Plain SQL (also Java) | XML / YAML / JSON / SQL |
| History table | `flyway_schema_history` | `DATABASECHANGELOG` (+ lock table) |
| Rollback | Write a new forward migration (undo is a paid feature) | Built-in `rollback` |
| Feel | Simple, SQL-first | Database-agnostic, more features |

### 39.3 Migration rules that save careers

1. **Never edit** a migration that already ran anywhere - write a new one.
2. Make changes **backward compatible** so the old app version still works during a rolling deploy (**expand -> migrate -> contract**: add the new column, deploy code using it, remove the old column later).
3. **Back up** before running migrations in production.
4. Run migrations **in the pipeline**, before the new app version starts - not by hand.
5. Big tables: adding an index or column can lock the table. Test on staging with production-sized data (Postgres: `CREATE INDEX CONCURRENTLY`).

---

# PART 5: Practice

---

## 40. The Big Picture

Everything from this guide in one production-style setup. Try to explain every arrow out loud - that is exactly what interviewers ask ("walk me through what happens when a user places an order").

![Big picture](images/31-big-picture.png)

1. **User -> CDN**: static files (JS, CSS, images) come from the nearest edge (section 19).
2. **CDN -> Nginx/HAProxy**: TLS termination, load balancing across app servers (sections 9-11).
3. **App servers**: stateless 12-factor processes, config from env vars (section 29), deployed from an artifact in **Nexus** that CI built with Maven/npm (sections 20-27).
4. **Redis**: cache-aside for hot data and sessions (section 35).
5. **PostgreSQL primary + replica**: writes to the primary, reads/reports from the replica (section 33).
6. **Kafka / RabbitMQ**: "order placed" events go to workers for emails and invoices (sections 37-38).
7. **Flyway** runs schema migrations in the pipeline before the new version starts (section 39).
8. **Backups**: nightly to S3, restore tested monthly (section 32).

---

## 41. Practice Labs

Do these in order. Each one builds on the previous.

### Lab 1: Static website with Nginx

1. Install Nginx (section 4).
2. Create `/var/www/example/index.html` and use [`static-site.conf`](examples/nginx/static-site.conf).
3. `sudo nginx -t && sudo systemctl reload nginx`, then `curl -H "Host: example.local" localhost`.
4. Break it on purpose: remove a `;`, run `nginx -t`, read the error. Request a missing page and find the 404 in `/var/log/nginx/access.log`.

✅ **Done when:** you can serve a page and explain every line of the config.

### Lab 2: Two sites, one server

1. Use [`virtual-hosts.conf`](examples/nginx/virtual-hosts.conf).
2. Add both names to your `hosts` file and open them in a browser.

✅ **Done when:** `shop` and `blog` show different pages from the same IP.

### Lab 3: Reverse proxy + 502 debugging

1. Run the sample app: `cd examples/build/node && npm start`.
2. Put Nginx in front with [`reverse-proxy.conf`](examples/nginx/reverse-proxy.conf).
3. Stop the app, get a `502`, find the matching line in `error.log` (`connect() failed (111: Connection refused)`).

✅ **Done when:** you can explain the difference between `502`, `503` and `504`.

### Lab 4: Load balancer with Docker

Follow [`examples/lab-load-balancer/README.md`](examples/lab-load-balancer/README.md): round robin, failover, `ip_hash`.

✅ **Done when:** you stop one container and users see no errors.

### Lab 5: HTTPS

1. Create a self-signed certificate (section 11.3) and configure `listen 443 ssl`.
2. Add the HTTP -> HTTPS redirect.
3. Bonus (needs a real domain + public VM): `certbot --nginx`.

✅ **Done when:** `curl -kI https://localhost` works and `http://` redirects with `301`.

### Lab 6: Cache it

1. Add `proxy_cache` (section 16.1) in front of the sample app with `add_header X-Cache-Status $upstream_cache_status;`.
2. Call it twice with `curl -I` and watch `MISS` turn into `HIT`.

✅ **Done when:** you can explain `max-age`, `no-cache` and `no-store`.

### Lab 7: Build and package

1. `cd examples/build && make help && make build`.
2. Build the Docker image: `cd node && docker build -t demo-app:1.0.0 .`.
3. Run two copies with different config: `-e APP_NAME=blue -p 3001:3000` and `-e APP_NAME=green -p 3002:3000`.

✅ **Done when:** you have one image running with two different configurations (12-factor III).

### Lab 8: Artifact repository

1. Run Nexus in Docker (section 27.1) and log in.
2. Create a `npm` proxy repo for `https://registry.npmjs.org` and run `npm install express --registry=<your proxy URL>`.
3. Look at the cached package in the Nexus UI.

✅ **Done when:** you can explain hosted vs proxy vs group repositories.

### Lab 9: Database backup and restore

1. `cd examples/databases && docker compose up -d postgres` and run the Flyway migrations (section 39.1).
2. Insert a few users, then `pg_dump` the database.
3. `DROP TABLE orders; DROP TABLE users;` (yes, really).
4. Restore into a new database with `pg_restore` and check the rows are back.

✅ **Done when:** you have restored data you deliberately destroyed, and know your RPO.

### Lab 10: Redis and queues

1. Start `redis`, `rabbitmq` and `kafka` from the playground.
2. In Redis: set a key with a TTL and watch it expire.
3. In RabbitMQ UI: create a queue, publish a message from the UI, get it back.
4. In Kafka: create `orders` with 3 partitions, produce 5 messages, consume them with two different `--group` names and see both groups get all messages.

✅ **Done when:** you can explain why Kafka keeps messages after they are read and RabbitMQ doesn't.

---

## 42. Troubleshooting Playbook

| Symptom | Check, in this order |
|---------|----------------------|
| Site not reachable at all | `systemctl status nginx` -> `ss -tlnp \| grep -E ':80\|:443'` -> firewall / security group -> DNS (`dig`) |
| `nginx: [emerg] ...` on reload | `sudo nginx -t` shows file + line. Usually missing `;` or `}` |
| `bind() to 0.0.0.0:80 failed (98: Address already in use)` | Another process owns the port: `sudo ss -tlnp \| grep :80` (Apache?) |
| `403 Forbidden` | File permissions / ownership (`namei -l /var/www/site/index.html`), missing `index` file, SELinux |
| `404 Not Found` | Wrong `root` / `alias`, wrong `server_name` matched (check `default_server`) |
| `502 Bad Gateway` | App down or wrong port: `curl localhost:3000` from the proxy host, `error.log` |
| `504 Gateway Timeout` | App too slow / DB slow: raise `proxy_read_timeout` only after finding why |
| `413 Request Entity Too Large` | `client_max_body_size 50m;` |
| Certificate errors | `openssl s_client -connect host:443 -servername host` -> expiry, name, missing chain (use `fullchain.pem`) |
| Infinite redirect loop | App redirects to https, proxy talks http to it: send `X-Forwarded-Proto` |
| "I deployed but see the old version" | Browser cache, CDN cache, Varnish/Nginx cache -> purge/invalidate, check `Cache-Control` |
| Build works locally, fails in CI | Missing lock file, different tool version (use wrappers `./mvnw` `./gradlew`), private repo credentials |
| `Too many connections` (DB) | Connection leak or no pooling; check `pg_stat_activity` / `SHOW PROCESSLIST` |
| Replica returns old data | Replication lag: `pg_stat_replication` / `SHOW REPLICA STATUS` |
| Queue keeps growing | Consumers dead or too slow; Kafka: `kafka-consumer-groups.sh --describe` |
| Flyway `checksum mismatch` | Someone edited an applied migration. Revert the edit, add a new migration |

```bash
# Universal first steps
sudo journalctl -u nginx --since "10 min ago"
sudo tail -n 50 /var/log/nginx/error.log
ss -tlnp                       # what is listening on which port
curl -v http://127.0.0.1:PORT  # test each hop directly
df -h ; free -m ; top          # disk, memory, CPU
```

---

## 43. Cheat Sheet

### Nginx

| Command | Does |
|---------|------|
| `sudo nginx -t` | Test config |
| `sudo nginx -T` | Test + print full effective config |
| `sudo systemctl reload nginx` | Apply config, no downtime |
| `sudo tail -f /var/log/nginx/error.log` | Watch errors |
| `curl -H "Host: x.com" http://IP/` | Test a virtual host without DNS |
| `curl -I URL` / `curl -v URL` | Headers / full conversation |

### Other web servers

| Command | Does |
|---------|------|
| `sudo apachectl configtest` | Test Apache config |
| `sudo a2ensite / a2enmod` | Enable Apache site / module |
| `haproxy -c -f /etc/haproxy/haproxy.cfg` | Test HAProxy config |
| `caddy validate --config Caddyfile` | Test Caddy config |
| `sudo certbot --nginx -d domain` | Get a Let's Encrypt cert |
| `openssl s_client -connect host:443 -servername host` | Inspect a live TLS cert |

### Build

| Command | Does |
|---------|------|
| `mvn clean package` / `mvn deploy` | Build jar / publish to repo |
| `./gradlew clean build` / `./gradlew publish` | Build / publish |
| `npm ci` / `npm run build` / `npm test` | CI install / build / test |
| `pip install -r requirements.txt` | Install Python deps |
| `python -m venv .venv` | Create virtual env |
| `make <target>` | Run a Makefile target |

### Databases and queues

| Command | Does |
|---------|------|
| `psql -h host -U user -d db` | Connect to Postgres |
| `mysql -h host -u user -p db` | Connect to MySQL |
| `pg_dump -Fc -f db.dump db` / `pg_restore -d newdb db.dump` | Postgres backup / restore |
| `mysqldump --single-transaction db \| gzip > db.sql.gz` | MySQL backup |
| `mongosh` / `mongodump` / `mongorestore` | MongoDB shell / backup / restore |
| `redis-cli INFO` / `redis-cli --scan` | Redis stats / safe key listing |
| `nodetool status` | Cassandra cluster health |
| `rabbitmqctl list_queues` | RabbitMQ queue depths |
| `kafka-consumer-groups.sh --describe --group G` | Kafka consumer lag |
| `flyway info` / `flyway migrate` | Migration status / apply |

### Ports to remember

| Port | Service | Port | Service |
|------|---------|------|---------|
| 80 / 443 | HTTP / HTTPS | 5432 | PostgreSQL |
| 22 | SSH | 3306 | MySQL |
| 3000 | Node apps | 27017 | MongoDB |
| 8080 | Java / Tomcat apps | 6379 | Redis |
| 8000 / 5000 | Python apps | 9042 | Cassandra |
| 8081 | Nexus | 5672 / 15672 | RabbitMQ / its UI |
| 6081 | Varnish | 9092 | Kafka |
| 8404 | HAProxy stats (common) | 9000 | PHP-FPM |

---

## 44. Interview Questions

<details>
<summary><b>1. What is the difference between a web server and an application server?</b></summary>

A web server (Nginx, Apache) handles HTTP connections, TLS, static files, compression, caching and proxying. An application server (Tomcat, Gunicorn, Node) runs the business logic and generates dynamic content. In production the web server sits in front as a reverse proxy.
</details>

<details>
<summary><b>2. Forward proxy vs reverse proxy?</b></summary>

A forward proxy acts for clients (they are configured to use it) - used for filtering and hiding clients. A reverse proxy acts for servers (clients don't know it exists) - used for TLS termination, load balancing, caching and protecting backends.
</details>

<details>
<summary><b>3. You get a 502 Bad Gateway. How do you debug it?</b></summary>

502 means the proxy could not get a valid response from the upstream. Check the Nginx `error.log` (e.g. "connection refused"), confirm the app is running (`systemctl status`, `docker ps`), confirm the port with `ss -tlnp`, `curl` the upstream directly from the proxy host, and verify `proxy_pass` points to the right host/port. Also check security groups / firewalls between proxy and app.
</details>

<details>
<summary><b>4. Explain how Nginx picks a server block and a location block.</b></summary>

Server block: by `listen` address/port, then the `Host` header against `server_name` (exact, then wildcard, then regex); if nothing matches, the `default_server`. Location: exact `=` match wins immediately; otherwise the longest prefix is remembered; if it has `^~`, use it; else regexes are checked in file order and the first match wins; if none, the remembered longest prefix is used.
</details>

<details>
<summary><b>5. What load balancing algorithms do you know?</b></summary>

Round robin (default), weighted round robin, least connections, IP hash (sticky), generic/consistent hash, and in some tools least response time or random. Combined with health checks (passive `max_fails` or active HTTP checks).
</details>

<details>
<summary><b>6. Layer 4 vs Layer 7 load balancing?</b></summary>

L4 works with IP and port (TCP/UDP) and cannot see HTTP - fast, used for databases and raw TCP (AWS NLB). L7 understands HTTP, so it can route by host, path, header or cookie, terminate TLS and modify headers (AWS ALB, Nginx, HAProxy http mode).
</details>

<details>
<summary><b>7. What happens during a TLS handshake?</b></summary>

The client sends supported versions, ciphers, a key share and the hostname (SNI). The server replies with its choice, its key share and its certificate. Both derive the same session keys; the client verifies the certificate chain to a trusted CA, the hostname and the validity dates. Then encrypted HTTP flows. TLS 1.3 does this in one round trip.
</details>

<details>
<summary><b>8. What is TLS termination and why do it at the load balancer?</b></summary>

Decrypting HTTPS at the proxy/LB and forwarding plain HTTP (or re-encrypted traffic) to backends. Benefits: certificates managed in one place, less CPU on apps, the proxy can inspect HTTP for routing and caching. For strict compliance you re-encrypt to the backend (end-to-end TLS).
</details>

<details>
<summary><b>9. Nginx vs Apache vs HAProxy vs Caddy?</b></summary>

Nginx: event-driven web server + reverse proxy, the default choice. Apache: module-rich, `.htaccess`, common for legacy/PHP. HAProxy: specialised L4/L7 load balancer with the best health checks and stats, no static files. Caddy: simple config and automatic HTTPS, great for small services.
</details>

<details>
<summary><b>10. What do max-age, no-cache and no-store mean?</b></summary>

`max-age=N`: response is fresh for N seconds. `no-cache`: may store, but must re-validate with the server (ETag/304) before each use. `no-store`: never store anywhere - for sensitive data. `s-maxage` applies to shared caches like CDNs; `private` forbids shared caches.
</details>

<details>
<summary><b>11. What is a CDN and how do you deploy new static files behind one?</b></summary>

A network of edge caches close to users that serves content from the nearest location and offloads the origin. For deploys, use content-hashed file names with long TTLs so new files have new URLs, keep `index.html` short-lived, and invalidate/purge (`aws cloudfront create-invalidation`) when needed.
</details>

<details>
<summary><b>12. What is Varnish and where does it sit?</b></summary>

An in-memory HTTP reverse-proxy cache configured with VCL. It sits between the TLS terminator (Nginx/HAProxy) and the application, answering cache hits from RAM and fetching misses from the backend. It supports purge/ban for invalidation and grace mode to serve stale content when the backend is down.
</details>

<details>
<summary><b>13. Maven vs Gradle?</b></summary>

Both build JVM projects and use Maven repositories. Maven uses declarative XML (`pom.xml`) and a fixed lifecycle (validate, compile, test, package, verify, install, deploy). Gradle uses a Groovy/Kotlin DSL and a task graph, with incremental builds and a build cache - usually faster and more flexible. Always use wrappers (`mvnw`, `gradlew`) in CI.
</details>

<details>
<summary><b>14. npm install vs npm ci?</b></summary>

`npm install` resolves versions and may update `package-lock.json`. `npm ci` deletes `node_modules` and installs exactly what the lock file says, failing if `package.json` and the lock file disagree. Use `npm ci` in pipelines for reproducible builds.
</details>

<details>
<summary><b>15. Why use an artifact repository like Nexus or Artifactory?</b></summary>

To store versioned build outputs (build once, deploy many), to proxy and cache public registries (faster, reliable builds, works if the internet or a package disappears), to control and scan what dependencies are allowed, and to have one audited source for all formats (Maven, npm, PyPI, Docker, Helm).
</details>

<details>
<summary><b>16. Release vs SNAPSHOT in Maven?</b></summary>

A SNAPSHOT (`1.2.0-SNAPSHOT`) is a moving development version that can be re-uploaded and is re-downloaded. A release (`1.2.0`) is immutable - once published it must never change. Production should deploy only releases.
</details>

<details>
<summary><b>17. Monolith vs microservices - which would you choose?</b></summary>

It depends on team size and needs. A monolith is simpler to build, deploy, test and debug - right for small teams and new products. Microservices allow independent deployment and scaling per service and fit many autonomous teams, but add network failures, distributed data, observability and platform complexity. Many teams start with a modular monolith and extract services when there is a clear reason.
</details>

<details>
<summary><b>18. Name some 12-factor principles and why DevOps cares.</b></summary>

Config in environment variables (same artifact everywhere), stateless processes (scale horizontally, survive restarts), logs to stdout (platform collects them), disposability (fast start, graceful SIGTERM), dev/prod parity, and strict build/release/run separation. They make apps container- and Kubernetes-friendly.
</details>

<details>
<summary><b>19. What are RPO and RTO?</b></summary>

RPO (Recovery Point Objective) is the maximum acceptable data loss measured in time - it drives backup frequency and replication. RTO (Recovery Time Objective) is the maximum acceptable downtime - it drives restore method, automation and standby systems.
</details>

<details>
<summary><b>20. Logical vs physical backups? What is PITR?</b></summary>

Logical backups export data as SQL/JSON (`pg_dump`, `mysqldump`) - portable, selective, slow for large DBs. Physical backups copy data files (`pg_basebackup`, XtraBackup, snapshots) - fast for large DBs, same version needed. Point-in-time recovery restores a base backup and replays the WAL/binlog up to a precise moment, e.g. just before an accidental `DELETE`.
</details>

<details>
<summary><b>21. Is replication a backup?</b></summary>

No. Replication copies every change - including mistakes like `DROP TABLE` or corrupted data - to replicas almost instantly. It provides availability and read scaling. Backups (with retention and off-site copies) protect against data loss.
</details>

<details>
<summary><b>22. Synchronous vs asynchronous replication? What is replication lag?</b></summary>

Async: the primary commits without waiting for replicas - fast, but recent transactions can be lost on failover. Sync/semi-sync: commit waits for at least one replica to confirm - safer, adds latency. Replication lag is how far a replica is behind the primary; reading from a lagging replica returns stale data.
</details>

<details>
<summary><b>23. When would you use Redis?</b></summary>

As a cache (cache-aside with TTLs), session store, rate limiter (`INCR` + `EXPIRE`), leaderboard (sorted sets), lightweight queue or pub/sub, and distributed locks. Configure `maxmemory` and an eviction policy, choose RDB/AOF persistence based on whether data can be lost, and use Sentinel or Cluster for HA.
</details>

<details>
<summary><b>24. MongoDB vs Cassandra?</b></summary>

MongoDB is a document store with rich queries and secondary indexes, using replica sets with a single primary per shard - good general-purpose NoSQL. Cassandra is a masterless wide-column store optimised for very high write throughput and multi-datacenter availability, with tunable consistency, where tables are designed around specific queries.
</details>

<details>
<summary><b>25. RabbitMQ vs Kafka?</b></summary>

RabbitMQ is a message broker: exchanges route messages to queues, consumers ACK and messages are removed - great for task queues and complex routing. Kafka is a distributed append-only log: messages are retained for a period, consumers track offsets, ordering is per partition and data can be replayed by many consumer groups - great for high-volume event streaming.
</details>

<details>
<summary><b>26. What is consumer lag in Kafka?</b></summary>

The difference between the latest offset in a partition and the last offset committed by a consumer group. Growing lag means consumers can't keep up - add consumers (up to the number of partitions), fix slow processing, or add partitions.
</details>

<details>
<summary><b>27. Why use Flyway or Liquibase?</b></summary>

To version schema changes in Git alongside code, apply them automatically and in order in every environment, record what ran (history table with checksums), and remove manual SQL in production. Rules: never edit applied migrations, keep changes backward compatible for rolling deploys, back up before running in production.
</details>

<details>
<summary><b>28. Walk me through deploying a new version with zero downtime.</b></summary>

CI builds and tests once and publishes a versioned artifact/image. The pipeline runs backward-compatible DB migrations. The load balancer drains one instance at a time (or blue/green, or Kubernetes rolling update), new instances start, pass health checks and are added back. Static assets use hashed names on the CDN. If metrics or errors go bad, roll back to the previous artifact.
</details>

---

## 45. Reference

**Web servers and proxies**

- [Nginx documentation](https://nginx.org/en/docs/) - [Beginner's guide](https://nginx.org/en/docs/beginners_guide.html) - [How Nginx processes a request](https://nginx.org/en/docs/http/request_processing.html)
- [Apache HTTP Server docs](https://httpd.apache.org/docs/2.4/)
- [HAProxy documentation](https://docs.haproxy.org/)
- [Caddy documentation](https://caddyserver.com/docs/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/) ⭐
- [Let's Encrypt](https://letsencrypt.org/docs/) - [Certbot](https://certbot.eff.org/)
- [MDN: HTTP status codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)

**Caching**

- [MDN: HTTP caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching)
- [Varnish documentation](https://varnish-cache.org/docs/)
- [Cloudflare Learning Center: What is a CDN?](https://www.cloudflare.com/learning/cdn/what-is-a-cdn/)
- [Amazon CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)

**Build and run**

- [Maven in 5 minutes](https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html) - [Build lifecycle](https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html)
- [Gradle user manual](https://docs.gradle.org/current/userguide/userguide.html)
- [npm docs](https://docs.npmjs.com/) - [Python packaging guide](https://packaging.python.org/)
- [GNU Make manual](https://www.gnu.org/software/make/manual/)
- [Sonatype Nexus Repository docs](https://help.sonatype.com/en/sonatype-nexus-repository.html) - [JFrog Artifactory docs](https://jfrog.com/help/r/jfrog-artifactory-documentation)
- [The Twelve-Factor App](https://12factor.net/) ⭐
- [Martin Fowler: Microservices](https://martinfowler.com/articles/microservices.html) - [MonolithFirst](https://martinfowler.com/bliki/MonolithFirst.html)

**Databases and messaging**

- [PostgreSQL docs](https://www.postgresql.org/docs/) - [Backup and restore](https://www.postgresql.org/docs/current/backup.html) - [Replication](https://www.postgresql.org/docs/current/high-availability.html)
- [MySQL reference manual](https://dev.mysql.com/doc/refman/8.0/en/) - [Replication](https://dev.mysql.com/doc/refman/8.0/en/replication.html)
- [MongoDB manual](https://www.mongodb.com/docs/manual/) - [Redis docs](https://redis.io/docs/) - [Valkey](https://valkey.io/) - [Apache Cassandra docs](https://cassandra.apache.org/doc/latest/)
- [RabbitMQ tutorials](https://www.rabbitmq.com/tutorials) ⭐ - [Apache Kafka quickstart](https://kafka.apache.org/quickstart)
- [Flyway docs](https://documentation.red-gate.com/flyway) - [Liquibase docs](https://docs.liquibase.com/)

**Practice**

- [roadmap.sh/devops](https://roadmap.sh/devops) - where this fits in the bigger DevOps picture
- [Killercoda](https://killercoda.com/) - free browser-based Linux / Docker playgrounds
- [Play with Docker](https://labs.play-with-docker.com/)

**Related guide in this series**

- [Version Control with Git for DevOps](https://github.com/KanishkaSemalPerera/Version-Control)

---

### 📁 What's in this repo

```
.
├── README.md                          ← this guide
├── images/                            ← all diagrams used in the guide
└── examples/
    ├── nginx/
    │   ├── nginx.conf                 ← main config with sane defaults
    │   ├── static-site.conf           ← serve a static website
    │   ├── virtual-hosts.conf         ← many sites on one server
    │   ├── reverse-proxy.conf         ← Nginx in front of an app
    │   ├── load-balancer.conf         ← upstream + algorithms + health
    │   └── ssl.conf                   ← HTTPS, redirect, HSTS
    ├── apache/vhost.conf              ← Apache vhost + proxy + balancer
    ├── haproxy/haproxy.cfg            ← L7 routing, health checks, stats
    ├── caddy/Caddyfile                ← automatic HTTPS
    ├── varnish/default.vcl            ← cache rules, purge, grace
    ├── lab-load-balancer/             ← Docker lab: Nginx + 3 apps
    ├── build/
    │   ├── maven/                     ← pom.xml + settings.xml (Nexus)
    │   ├── gradle/                    ← build.gradle.kts
    │   ├── node/                      ← 12-factor Node app + Dockerfile
    │   ├── python/                    ← requirements.txt + pyproject.toml
    │   └── Makefile                   ← one interface for every tool
    ├── twelve-factor/.env.example     ← config through environment
    └── databases/
        ├── docker-compose.yml         ← MySQL, Postgres, Mongo, Redis, Cassandra, RabbitMQ, Kafka
        ├── backup/                    ← backup + restore scripts
        ├── flyway/                    ← versioned SQL migrations
        └── liquibase/                 ← YAML changelog
```

⭐ If this guide helped you, star the repo and share it with someone starting their DevOps journey.
