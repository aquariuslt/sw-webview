import {execInWorker} from "../util/exec-in-worker";
import {waitUntilWorkerIsActivated} from "../util/sw-lifecycle";
import {assert} from "chai";
import {unregisterEverything} from "../util/unregister-everything";

describe("CacheStorage", () => {
    afterEach(() => {
        return navigator.serviceWorker
            .getRegistration("/fixtures/")
            .then(reg => {
                if (reg !== undefined){
                    return execInWorker(
                        reg.active!,
                        `
                    console.log("(afterEach): END CACHE STORAGE TEST");
                return caches.keys().then(keys => {
                    return Promise.all(keys.map(k => caches.delete(k)));
                });
            `
                    );
                } else {
                    return Promise.resolve(null);
                }
            })
            .then(() => {
                console.log("unregisterEverything.")
                return unregisterEverything();
            });
    });

    it.skip("should open a cache and record it in list of keys", () => {
        console.log("============= Start Cache Storage 1 ===============")
        return navigator.serviceWorker
            .register("/fixtures/exec-worker.js")
            .then(reg => {
                return waitUntilWorkerIsActivated(reg.installing!);
            })
            .then(worker => {
                return execInWorker(
                    worker,
                    `
                    console.log("OPEN test-cache 1");
                        return caches.open("test-cache")
                        .then(() => {
                    return caches.keys()
                })
            `
                );
            })
            .then((response: string[]) => {
                assert.equal(response.length, 1);
                assert.equal(response[0], "test-cache");
            });
    });

    it.skip("should return correct values for has()", () => {
        console.log("============= Start Cache Storage 2 ===============")
        return navigator.serviceWorker
            .register("/fixtures/exec-worker.js")
            .then(reg => {
                return waitUntilWorkerIsActivated(reg.installing!);
            })
            .then(worker => {
                return execInWorker(
                    worker,
                    "return caches.has('test-cache')"
                ).then(response => {
                    assert.equal(response, false);
                    return execInWorker(
                        worker,
                        `
                            console.log("OPEN test-cache 2");
                            return caches.open('test-cache')
                                .then(() => {
                                    return caches.has('test-cache')
                                })
                        `
                    );
                });
            })
            .then(response2 => {
                assert.equal(response2, true);
            });
    });

    it.skip("should delete() successfully", () => {
        console.log("============= Start Cache Storage 2 ===============")
        return navigator.serviceWorker
            .register("/fixtures/exec-worker.js")
            .then(reg => {
                return waitUntilWorkerIsActivated(reg.installing!);
            })
            .then(worker => {
                return execInWorker(
                    worker,
                    `
                            console.log("OPEN test-cache 3");
                            return caches.open('test-cache')
                        .then(() => caches.delete('test-cache'))
                        .then(() => caches.has('test-cache'))`
                );
            })
            .then(response2 => {
                assert.equal(response2, false);
            });
    });
});
