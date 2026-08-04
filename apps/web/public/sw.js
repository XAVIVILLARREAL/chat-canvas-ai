const CACHE = 'empresa-dev-v1'
const PRECACHE = ['/', '/manifest.json', '/icon.svg']

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((c) => c.addAll(PRECACHE)))
  self.skipWaiting()
})

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))),
    ),
  )
  self.clients.claim()
})

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url)
  if (url.pathname.startsWith('/api/')) return
  event.respondWith(
    caches.match(event.request).then((hit) => {
      if (hit) return hit
      return fetch(event.request).then((res) => {
        if (url.origin === location.origin) {
          const clone = res.clone()
          caches.open(CACHE).then((c) => c.put(event.request, clone))
        }
        return res
      })
    }),
  )
})
