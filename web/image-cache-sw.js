const CACHE_NAME = 'bgg-images-v1';
const MAX_ENTRIES = 500;
const IMAGE_PATH = '/cors-proxy/_';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(
        names
          .filter((name) => name.startsWith('bgg-images-') && name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      )
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  if (!url.pathname.includes(IMAGE_PATH)) return;

  event.respondWith(
    caches.open(CACHE_NAME).then((cache) =>
      cache.match(event.request).then((cached) => {
        if (cached) return cached;

        return fetch(event.request).then((response) => {
          if (response.ok) {
            cache.put(event.request, response.clone());
            trimCache(cache);
          }
          return response;
        });
      })
    )
  );
});

function trimCache(cache) {
  cache.keys().then((keys) => {
    if (keys.length > MAX_ENTRIES) {
      cache.delete(keys[0]).then(() => trimCache(cache));
    }
  });
}
