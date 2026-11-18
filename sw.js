// Energie Inzicht - Service Worker
// Versie wordt automatisch bijgewerkt bij elke deploy

const CACHE = 'energie-v3';

self.addEventListener('install', e => {
  // Direct activeren zonder te wachten op oude clients
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  // Verwijder alleen eigen oude caches (niet die van Cucina of Boodschappen op hetzelfde adres)
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k.startsWith('energie-') && k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  // Opslaan en inloggen niet via de cache; gegevens uit de database ook niet
  if (e.request.method !== 'GET') return;
  if (new URL(e.request.url).hostname.endsWith('supabase.co')) return;
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
