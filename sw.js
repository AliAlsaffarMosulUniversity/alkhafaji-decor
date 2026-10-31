// Offline shell for the installed app. Bump VERSION after changing site files.
const VERSION = "v13";
const SHELL = `shell-${VERSION}`;
const RUNTIME = `runtime-${VERSION}`;
const SHELL_FILES = ["./", "./index.html", "./config.js", "./manifest.webmanifest",
  "./icon-192.png", "./icon-512.png", "./apple-touch-icon.png", "./logo.jpg", "./logo-mark.png"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(SHELL).then(c => c.addAll(SHELL_FILES)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== SHELL && k !== RUNTIME).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);

  // site pages and files: network first, cached copy when offline
  if (url.origin === location.origin) {
    e.respondWith(fetch(req).then(res => {
      const copy = res.clone(); caches.open(SHELL).then(c => c.put(req, copy)); return res;
    }).catch(() => caches.match(req).then(r => r || caches.match("./index.html"))));
    return;
  }

  // design photos (never change once uploaded) and fonts/library: cache first
  const cacheable = url.pathname.includes("/storage/v1/object/public/")
    || url.host === "fonts.googleapis.com" || url.host === "fonts.gstatic.com" || url.host === "cdn.jsdelivr.net";
  if (cacheable) {
    e.respondWith(caches.open(RUNTIME).then(c => c.match(req).then(hit => hit || fetch(req).then(res => {
      // only real successes are kept: an opaque or failed response could hide an error forever
      if (res.ok) c.put(req, res.clone());
      return res;
    }))));
  }
  // everything else (database, login) goes straight to the network
});
