// Energie Inzicht - Service Worker
// Versie wordt automatisch bijgewerkt bij elke deploy

const CACHE = 'energie-v2';

self.addEventListener('install', e => {
  // Direct activeren zonder te wachten op oude clients
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  // Verwijder alle oude caches
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  // Network first: altijd proberen de nieuwste versie te laden
  // Alleen als het netwerk faalt, gebruik de cache
  e.respondWith(
    fetch(e.request)
      .then(res => {
        // Sla op in cache voor offline gebruik
        const clone = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, clone));
        return res;
      })
      .catch(() => caches.match(e.request))
  );
});
