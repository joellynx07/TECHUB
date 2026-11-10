const V = "lynxhub-v2",
  SHELL = ["./", "index.html", "icon.svg", "manifest.webmanifest"];
self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(V).then((c) => c.addAll(SHELL)));
  self.skipWaiting();
});
self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches
      .keys()
      .then((k) =>
        Promise.all(k.filter((x) => x !== V).map((x) => caches.delete(x))),
      ),
  );
  self.clients.claim();
});
self.addEventListener("fetch", (e) => {
  const r = e.request;
  if (r.method !== "GET") return;
  const u = new URL(r.url);
  if (u.hostname.endsWith("supabase.co")) return; // live data is never cached here
  e.respondWith(
    fetch(r)
      .then((res) => {
        if (
          res.ok &&
          (u.origin === location.origin ||
            /gstatic|googleapis|jsdelivr|tailwindcss/.test(u.hostname))
        ) {
          const c = res.clone();
          caches.open(V).then((x) => x.put(r, c));
        }
        return res;
      })
      .catch(() =>
        caches.match(r).then((m) => m || caches.match("index.html")),
      ),
  );
});
