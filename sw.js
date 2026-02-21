// Service Worker - مكتب النخبة للمحاماة
const CACHE_NAME = 'nokhba-law-v1.0.0';
const OFFLINE_URL = './index.html';

const STATIC_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  'https://fonts.googleapis.com/css2?family=Tajawal:wght@300;400;500;700;800;900&family=Amiri:wght@400;700&display=swap',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2'
];

// ===== INSTALL =====
self.addEventListener('install', event => {
  console.log('[SW] Installing...');
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll(STATIC_ASSETS.filter(url => !url.startsWith('https://')));
    }).then(() => self.skipWaiting())
  );
});

// ===== ACTIVATE =====
self.addEventListener('activate', event => {
  console.log('[SW] Activating...');
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames
          .filter(name => name !== CACHE_NAME)
          .map(name => caches.delete(name))
      );
    }).then(() => self.clients.claim())
  );
});

// ===== FETCH =====
self.addEventListener('fetch', event => {
  // Skip Supabase API calls - always fetch from network
  if (event.request.url.includes('supabase.co')) {
    return event.respondWith(
      fetch(event.request).catch(() => {
        return new Response(JSON.stringify({ error: 'offline' }), {
          headers: { 'Content-Type': 'application/json' }
        });
      })
    );
  }

  // For HTML pages - Network First, then cache
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match(OFFLINE_URL);
      })
    );
    return;
  }

  // For other assets - Cache First
  event.respondWith(
    caches.match(event.request).then(cached => {
      if (cached) return cached;
      return fetch(event.request).then(response => {
        if (response.ok) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
        }
        return response;
      });
    })
  );
});

// ===== PUSH NOTIFICATIONS =====
self.addEventListener('push', event => {
  if (!event.data) return;
  const data = event.data.json();
  event.waitUntil(
    self.registration.showNotification(data.title || 'مكتب النخبة', {
      body: data.body || '',
      icon: './icons/icon-192.png',
      badge: './icons/icon-72.png',
      dir: 'rtl',
      lang: 'ar',
      vibrate: [200, 100, 200],
      data: { url: data.url || './' },
      actions: [
        { action: 'open', title: 'فتح التطبيق' },
        { action: 'close', title: 'إغلاق' }
      ]
    })
  );
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  if (event.action === 'open' || !event.action) {
    event.waitUntil(
      clients.openWindow(event.notification.data?.url || './')
    );
  }
});
