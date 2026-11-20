# Lab: Nginx Load Balancer with Docker

Three tiny app containers, one Nginx in front. You will **see** round robin, failover and algorithm changes with your own eyes.

```bash
cd examples/lab-load-balancer
docker compose up -d

# 1. Round robin: answers rotate app1 -> app2 -> app3
for i in 1 2 3 4 5 6; do curl -s http://localhost:8080; done

# 2. Which backend answered? Look at the X-Upstream header
curl -I http://localhost:8080

# 3. Failover: kill one app, traffic keeps flowing to the others
docker compose stop app2
for i in 1 2 3 4 5 6; do curl -s http://localhost:8080; done
docker compose start app2

# 4. Sticky sessions: uncomment ip_hash; in nginx.conf, then
docker compose restart nginx
for i in 1 2 3 4; do curl -s http://localhost:8080; done   # always the same app

# 5. Read the logs
docker compose logs nginx

# Clean up
docker compose down
```

**What to notice**

- You never talk to the apps directly: only port `8080` (Nginx) is published.
- When `app2` is stopped, Nginx marks it failed and skips it - users see no error.
- Changing the config needs a reload/restart. On a real server: `sudo nginx -t && sudo systemctl reload nginx`.
