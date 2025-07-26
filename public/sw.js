// Service Worker for BudgieBreedingTracker PWA
const CACHE_NAME = 'budgiebreedingtracker-v2';
const STATIC_CACHE = 'budgiebreedingtracker-static-v2';
const DYNAMIC_CACHE = 'budgiebreedingtracker-dynamic-v2';
const IMAGE_CACHE = 'budgiebreedingtracker-images-v2';
const API_CACHE = 'budgiebreedingtracker-api-v2';

// Cache edilecek statik dosyalar
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/offline.html',
  '/manifest.json',
  '/favicon.ico',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png'
];

// Cache stratejileri
const CACHE_STRATEGIES = {
  // Statik dosyalar için Cache First
  STATIC_FIRST: 'static-first',
  // Dinamik içerik için Network First
  NETWORK_FIRST: 'network-first',
  // Resimler için Cache First
  IMAGE_FIRST: 'image-first',
  // API çağrıları için Network First
  API_FIRST: 'api-first',
  // Offline için Cache Only
  OFFLINE_ONLY: 'cache-only'
};

// Service Worker kurulumu
self.addEventListener('install', (event) => {
  console.log('Service Worker installing...');
  
  event.waitUntil(
    Promise.all([
      // Statik cache'i oluştur
      caches.open(STATIC_CACHE).then((cache) => {
        console.log('Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      }),
      
      // Diğer cache'leri oluştur
      caches.open(DYNAMIC_CACHE),
      caches.open(IMAGE_CACHE),
      caches.open(API_CACHE)
    ]).then(() => {
      console.log('Service Worker installed');
      return self.skipWaiting();
    })
  );
});

// Service Worker aktivasyonu
self.addEventListener('activate', (event) => {
  console.log('Service Worker activating...');
  
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          // Eski cache'leri temizle
          if (cacheName !== STATIC_CACHE && 
              cacheName !== DYNAMIC_CACHE && 
              cacheName !== IMAGE_CACHE &&
              cacheName !== API_CACHE) {
            console.log('Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('Service Worker activated');
      return self.clients.claim();
    })
  );
});

// Fetch olaylarını yakala
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Sadece GET isteklerini cache'le
  if (request.method !== 'GET') {
    return;
  }

  // Farklı URL türleri için farklı stratejiler
  if (isStaticAsset(url.pathname)) {
    event.respondWith(handleStaticAsset(request));
  } else if (isImage(url.pathname)) {
    event.respondWith(handleImage(request));
  } else if (isApiCall(url.pathname)) {
    event.respondWith(handleApiCall(request));
  } else {
    event.respondWith(handleDynamicContent(request));
  }
});

// Statik dosya kontrolü
function isStaticAsset(pathname) {
  return STATIC_ASSETS.includes(pathname) || 
         pathname.startsWith('/static/') ||
         pathname.endsWith('.js') ||
         pathname.endsWith('.css') ||
         pathname.endsWith('.woff') ||
         pathname.endsWith('.woff2') ||
         pathname.startsWith('/icons/');
}

// Resim kontrolü
function isImage(pathname) {
  return pathname.match(/\.(jpg|jpeg|png|gif|webp|svg)$/i);
}

// API çağrısı kontrolü
function isApiCall(pathname) {
  return pathname.startsWith('/api/') || 
         pathname.includes('supabase') ||
         pathname.includes('rest/v1');
}

// Statik dosyalar için Cache First stratejisi
async function handleStaticAsset(request) {
  try {
    // Önce cache'den kontrol et
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }

    // Cache'de yoksa network'ten al
    const networkResponse = await fetch(request);
    
    // Başarılı ise cache'e kaydet
    if (networkResponse.ok) {
      const cache = await caches.open(STATIC_CACHE);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    console.error('Static asset fetch failed:', error);
    // Offline fallback
    return caches.match('/offline.html');
  }
}

// Resimler için Cache First stratejisi
async function handleImage(request) {
  try {
    // Önce cache'den kontrol et
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }

    // Cache'de yoksa network'ten al
    const networkResponse = await fetch(request);
    
    // Başarılı ise cache'e kaydet
    if (networkResponse.ok) {
      const cache = await caches.open(IMAGE_CACHE);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    console.error('Image fetch failed:', error);
    // Offline fallback - placeholder resim
    return new Response('', {
      status: 404,
      statusText: 'Image not available offline'
    });
  }
}

// API çağrıları için Network First stratejisi
async function handleApiCall(request) {
  try {
    // Önce network'ten dene
    const networkResponse = await fetch(request);
    
    // Başarılı ise cache'e kaydet
    if (networkResponse.ok) {
      const cache = await caches.open(API_CACHE);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    console.error('API call failed, trying cache:', error);
    
    // Network başarısız ise cache'den dene
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }

    // Cache'de de yoksa offline response
    return new Response(JSON.stringify({
      error: 'Offline - API not available',
      message: 'Bu işlem için internet bağlantısı gereklidir',
      timestamp: new Date().toISOString()
    }), {
      status: 503,
      statusText: 'Service Unavailable',
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
}

// Dinamik içerik için Network First stratejisi
async function handleDynamicContent(request) {
  try {
    // Önce network'ten dene
    const networkResponse = await fetch(request);
    
    // Başarılı ise cache'e kaydet
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    console.error('Dynamic content fetch failed, trying cache:', error);
    
    // Network başarısız ise cache'den dene
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }

    // Cache'de de yoksa offline sayfası
    return caches.match('/offline.html');
  }
}

// Background Sync için
self.addEventListener('sync', (event) => {
  console.log('Background sync triggered:', event.tag);
  
  if (event.tag === 'background-sync') {
    event.waitUntil(performBackgroundSync());
  }
});

// Background sync işlemi
async function performBackgroundSync() {
  try {
    const queue = await getOfflineQueue();
    
    for (const item of queue) {
      await processOfflineItem(item);
      await removeFromOfflineQueue(item.id);
    }
    
    console.log('Background sync completed');
  } catch (error) {
    console.error('Background sync failed:', error);
  }
}

// Offline queue'yu al
async function getOfflineQueue() {
  try {
    const response = await caches.match('/api/offline-queue');
    if (response) {
      return await response.json();
    }
    return [];
  } catch (error) {
    console.error('Failed to get offline queue:', error);
    return [];
  }
}

// Offline item'ı işle
async function processOfflineItem(item) {
  try {
    const response = await fetch(item.url, {
      method: item.method,
      headers: item.headers,
      body: item.body
    });
    
    if (response.ok) {
      console.log('Offline item processed successfully:', item.id);
    } else {
      console.error('Failed to process offline item:', item.id);
    }
  } catch (error) {
    console.error('Error processing offline item:', error);
  }
}

// Offline queue'dan item'ı kaldır
async function removeFromOfflineQueue(id) {
  try {
    const queue = await getOfflineQueue();
    const updatedQueue = queue.filter(item => item.id !== id);
    
    const cache = await caches.open(DYNAMIC_CACHE);
    await cache.put('/api/offline-queue', new Response(JSON.stringify(updatedQueue)));
  } catch (error) {
    console.error('Failed to remove from offline queue:', error);
  }
}

// Push notification'ları için
self.addEventListener('push', (event) => {
  console.log('Push notification received:', event);
  
  const options = {
    body: event.data ? event.data.text() : 'Yeni bildirim',
    icon: '/icons/icon-192x192.png',
    badge: '/icons/icon-72x72.png',
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1
    },
    actions: [
      {
        action: 'explore',
        title: 'Görüntüle',
        icon: '/icons/icon-72x72.png'
      },
      {
        action: 'close',
        title: 'Kapat',
        icon: '/icons/icon-72x72.png'
      }
    ]
  };

  event.waitUntil(
    self.registration.showNotification('BudgieBreedingTracker', options)
  );
});

// Notification click olayları
self.addEventListener('notificationclick', (event) => {
  console.log('Notification clicked:', event);
  
  event.notification.close();
  
  if (event.action === 'explore') {
    event.waitUntil(
      clients.openWindow('/')
    );
  } else if (event.action === 'close') {
    // Sadece kapat
  } else {
    // Varsayılan davranış
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Notification action'ları
function handleNotificationAction(action, data) {
  switch (action) {
    case 'view-bird':
      clients.openWindow(`/birds/${data.birdId}`);
      break;
    case 'view-breeding':
      clients.openWindow(`/breeding/${data.breedingId}`);
      break;
    case 'view-eggs':
      clients.openWindow('/eggs');
      break;
    default:
      clients.openWindow('/');
  }
}

// Cache temizleme
async function cleanupCache() {
  try {
    const cacheNames = await caches.keys();
    
    for (const cacheName of cacheNames) {
      if (cacheName.startsWith('budgiebreedingtracker-')) {
        const cache = await caches.open(cacheName);
        const requests = await cache.keys();
        
        // 7 günden eski cache'leri temizle
        const weekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
        
        for (const request of requests) {
          const response = await cache.match(request);
          if (response) {
            const date = response.headers.get('date');
            if (date && new Date(date).getTime() < weekAgo) {
              await cache.delete(request);
            }
          }
        }
      }
    }
    
    console.log('Cache cleanup completed');
  } catch (error) {
    console.error('Cache cleanup failed:', error);
  }
}

// Haftalık cache temizleme
setInterval(cleanupCache, 7 * 24 * 60 * 60 * 1000);

// PWA güncelleme mesajları
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'GET_VERSION') {
    event.ports[0].postMessage({ version: CACHE_NAME });
  }
});

// PWA install event'i
self.addEventListener('install', (event) => {
  console.log('PWA installing...');
  event.waitUntil(self.skipWaiting());
});

// PWA activate event'i
self.addEventListener('activate', (event) => {
  console.log('PWA activating...');
  event.waitUntil(self.clients.claim());
});

console.log('Service Worker loaded successfully'); 