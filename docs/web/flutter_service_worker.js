'use strict';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "assets/AssetManifest.json": "052da70fd40d9ece64632d0aeba49f8f",
"assets/assets/logo.png": "1d125fae1b72f8e01adc8433196255b7",
"assets/FontManifest.json": "580ff1a5d08679ded8fcf5c6848cece7",
"assets/fonts/MaterialIcons-Regular.ttf": "56d3ffdef7a25659eab6a68a3fbfaf16",
"assets/LICENSE": "db5f38514a34955eb6a7ce0a0098502c",
"favicon.png": "d0e2d7b3803153e9f24dfd0d27999c92",
"icons/Icon-192.png": "17411191f9a4cdd8b467d8be638a253b",
"icons/Icon-512.png": "f80d2134fe0e4772047760e60bdff3d3",
"index.html": "40d2b7309ead26936819f9f4d77d6566",
"/": "40d2b7309ead26936819f9f4d77d6566",
"main.dart.js": "3d850c6e73c658299e47a26e7444e41b",
"manifest.json": "df9b3b9f50a996639a1b033b8dc9a8a6"
};

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (cacheName) {
      return caches.delete(cacheName);
    }).then(function (_) {
      return caches.open(CACHE_NAME);
    }).then(function (cache) {
      return cache.addAll(Object.keys(RESOURCES));
    })
  );
});

self.addEventListener('fetch', function (event) {
  event.respondWith(
    caches.match(event.request)
      .then(function (response) {
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
  );
});
