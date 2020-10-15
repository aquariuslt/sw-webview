self.addEventListener("fetch", e => {
    let requestURL = new URL(e.request.url);
    // console.log(requestURL.searchParams.);

    console.log('[Test:RespondWith] catching url:', e.request.url);

    let responseJSON = {
        success: true,
        queryValue: requestURL.searchParams.get("test")
    };

    let response = new Response(JSON.stringify(responseJSON), {
        headers: {
            "content-type": "application/json"
        }
    });

    e.respondWith(response);
});

console.log('[Test:RespondWith] addEventListener complete');

self.addEventListener("install", e => {
    console.log('[Test:Install] test-response-worker.js installed')
    self.skipWaiting();
});

self.addEventListener("activate", e => {
    console.log('[Test:Activate] test-response-worker.js activate')
    e.waitUntil(self.clients.claim());
});
