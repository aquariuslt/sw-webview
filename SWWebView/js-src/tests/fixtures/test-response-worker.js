self.addEventListener("fetch", e => {
    let requestURL = new URL(e.request.url);
    // console.log(requestURL.searchParams.);

    console.log('[test-response-worker.js] catching url:', e.request.url);

    if(requestURL.searchParams.get('test')){
        let responseJSON = {
            success: true,
            queryValue: requestURL.searchParams.get("test")
        };

        let response = new Response(JSON.stringify(responseJSON), {
            headers: {
                "content-type": "application/json"
            }
        });

        console.log('[test-response-worker.js] using cached response with url:', e.request.url);


        e.respondWith(response);
    }
    else {
        return e.respondWith(fetch(e.request));
    }
});

console.log('[test-response-worker.js] addEventListener fetch complete');


self.addEventListener("install", e => {
    console.log('[test-response-worker.js] test-response-worker.js installed')
    self.skipWaiting();
});

self.addEventListener("activate", e => {
    console.log('[test-response-worker.js] test-response-worker.js activate')
    e.waitUntil(self.clients.claim());
});


