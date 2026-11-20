// A 12-factor friendly HTTP server with zero dependencies.
//   npm start                       -> http://localhost:3000
//   PORT=4000 APP_NAME=blue npm start
// Put Nginx in front of it with examples/nginx/reverse-proxy.conf

const http = require("http");
const os = require("os");

// Factor III: config comes from environment variables, with safe defaults
const PORT = process.env.PORT || 3000;
const APP_NAME = process.env.APP_NAME || "demo-app";

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    return res.end("ok\n");
  }

  const body = {
    app: APP_NAME,
    host: os.hostname(),                                  // which container/server answered
    path: req.url,
    clientIp: req.headers["x-real-ip"] || req.socket.remoteAddress,
    forwardedProto: req.headers["x-forwarded-proto"] || "http",
  };

  // Factor XI: logs go to stdout, the platform collects them
  console.log(JSON.stringify({ level: "info", method: req.method, path: req.url }));

  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body, null, 2) + "\n");
});

server.listen(PORT, () => console.log(`${APP_NAME} listening on :${PORT}`));

// Factor IX: shut down gracefully when the platform stops us
process.on("SIGTERM", () => {
  console.log("SIGTERM received, closing server");
  server.close(() => process.exit(0));
});
