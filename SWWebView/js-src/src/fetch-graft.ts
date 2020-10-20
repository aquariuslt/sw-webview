import {SW_PROTOCOL, GRAFTED_REQUEST_HEADER} from "swwebview-settings";

// We can't read POST bodies in native code, so we're doing the super-gross:
// putting it in a custom header. Hoping we can get rid of this nonsense soon.

const originalFetch = fetch;

function graftedFetch(request: RequestInfo, opts?: RequestInit) {

    let url = request instanceof Request ? request.url : request;
    console.log('[fetch-grafted] 捕获请求: ' + url);

    if (!opts) {
        // no body, so none of this matters
        console.log('[fetch-grafted] 因opts为空，使用原始fetch for:', url);
        return originalFetch(request, opts);
    }

    let resolvedURL = new URL(url, window.location.href);

    if (resolvedURL.protocol !== SW_PROTOCOL + ":") {
        // if we're not fetching on the SW protocol, then this
        // doesn't matter.
        console.log('[fetch-grafted] protocol 不是 sw:，使用原始fetch for:', url);
        return originalFetch(request, opts);
    }

    opts.headers = opts.headers || {};
    opts.headers[GRAFTED_REQUEST_HEADER] = opts.body;
    console.log('[fetch-grafted] 已设置 GRAFTED_REQUEST_HEADER for:', url);

    return originalFetch(request, opts);
}

(graftedFetch as any).__bodyGrafted = true;

if ((originalFetch as any).__bodyGrafted !== true) {
    (window as any).fetch = graftedFetch;

    console.log('[fetch-grafted] fetch 替换成功');
    const originalSend = XMLHttpRequest.prototype.send;
    const originalOpen = XMLHttpRequest.prototype.open;

    XMLHttpRequest.prototype.open = function (method, url) {
        let resolvedURL = new URL(url, window.location.href);
        if (resolvedURL.protocol === SW_PROTOCOL + ":") {
            console.log('[fetch-grafted] 设置 _graftBody = true');
            this._graftBody = true;
        }
        console.log('[fetch-grafted] 使用 wrap 过的 XHR 请求 open(), url:' + resolvedURL);
        originalOpen.apply(this, arguments);
    };

    XMLHttpRequest.prototype.send = function (data) {
        if (this._graftBody === true) {
            console.log('[fetch-grafted] wrap 过的 XHR 请求准备发送前设置 header:' + GRAFTED_REQUEST_HEADER + ',' + data)
            this.setRequestHeader(GRAFTED_REQUEST_HEADER, data);
        }
        console.log('[fetch-grafted] 使用 wrap 过的 XHR 请求 send():' + data);
        originalSend.apply(this, arguments);
    };

    // @ts-ignore
    window.isNewFetch = 1;
    // @ts-ignore
    window.isNewXHR = 1;
}
