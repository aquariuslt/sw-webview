import {assert} from "chai";
import {withIframe} from "../util/with-iframe";
import {waitUntilWorkerIsActivated} from "../util/sw-lifecycle";
import {unregisterEverything} from "../util/unregister-everything";
import {execInWorker} from "../util/exec-in-worker";

describe("Service Worker", () => {
    afterEach(() => {
        return unregisterEverything();
    });

    it.skip("Should post a message", done => {
        let channel = new MessageChannel();

        let numberOfMessages = 0;

        channel.port2.onmessage = function (e) {
            console.timeEnd("Round-trip message");
            numberOfMessages++;
            console.log(e);

            e.ports[0].onmessage = () => {
                console.timeEnd("Second round-trip message");
                done();
            };
            console.time("Second round-trip message");
            e.ports[0].postMessage("reply");
        };

        navigator.serviceWorker
            .register("/fixtures/test-message-reply-worker.js")
            .then(reg => {
                return waitUntilWorkerIsActivated(reg.installing!);
            })
            .then(worker => {
                console.time("Round-trip message");
                worker.postMessage({hello: "there", port: channel.port1}, [
                    channel.port1
                ]);
            });
    });

    it.skip("Should import a script successfully", () => {
        return navigator.serviceWorker
            .register("/fixtures/exec-worker.js")
            .then(reg => {
                return waitUntilWorkerIsActivated(reg.installing!);
            })
            .then(worker => {
                return execInWorker(
                    worker,
                    `
                self.testValue = "unset";
                importScripts("./script-to-import.js");
                return self.testValue;
                `
                );
            })
            .then(returnValue => {
                assert.equal(returnValue, "set");
            });
    });

    it.skip("Should import multiple scripts successfully", () => {
        return navigator.serviceWorker
            .register("/fixtures/exec-worker.js")
            .then(reg => {
                return waitUntilWorkerIsActivated(reg.installing!);
            })
            .then(worker => {
                return execInWorker(
                    worker,
                    `
                self.testValue = "unset";
                importScripts("./script-to-import.js","./script-to-import2.js");
                return self.testValue;
                `
                );
            })
            .then(returnValue => {
                assert.equal(returnValue, "set again");
            });
    });

    it("Should send fetch events to worker, and worker should respond", (done) => {
        navigator.serviceWorker.register("/fixtures/test-response-worker.js")
            .then((reg)=>{
                new Promise((resolve => {
                    navigator.serviceWorker.oncontrollerchange = resolve;
                }))

                // return Promise.resolve(reg);
            })
            .then(reg => {
                console.log('[universal/service-worker.ts] complete registeration:', reg);
                window.fetch('/fixtures/testfile?test=bb')
                    .then((res) => {
                        return res.json();
                    }).then((res) => {
                    console.log('[universal/service-worker.ts] bb response' + JSON.stringify(res))
                });

                console.log('[universal/service-worker.ts] check if is new Fetch:', window.isNewFetch)
                console.log('[universal/service-worker.ts] check if is new XHR:', window.isNewXHR)

                console.log('[universal/service-worker.ts] check referer before XHR, location.href:', window.location.href, 'document.referrer', document.referrer)

                const xhrRequest = new XMLHttpRequest();
                xhrRequest.addEventListener('load', () => {
                    console.log('[universal/service-worker.ts] response.status:', xhrRequest.status);
                    console.log('[universal/service-worker.ts] response.content:', xhrRequest.responseText)
                })
                // xhrRequest.setRequestHeader("Referrer-Policy", "origin");
                xhrRequest.open('GET', '/fixtures/testfile?test=axios');
                xhrRequest.send();

                return window.fetch("/fixtures/testfile?test=hello");
            })
            .then(res => {
                assert.equal(res.status, 200);
                assert.equal(
                    res.headers.get("content-type"),
                    "application/json"
                );
                return res.json();
            })
            .then(json => {
                assert.equal(json.success, true);
                assert.equal(json.queryValue, "hello");
                done();
            })



    });


    it.skip('Should send xhr events to worker, and worker catch xhr as fetch event and respond', (done) => {
        withIframe("/fixtures/blank.html", ({window, navigator}) => {
            navigator.serviceWorker.register("./test-response-worker.js");

            console.log('[universal/service-worker.ts] # should send xhr events to worker, and worker catch xhr as fetch event and respond')
            return new Promise(fulfill => {
                navigator.serviceWorker.oncontrollerchange = fulfill;
            })
                .then(reg => {
                    /**
                     * use XHR
                     **/
                    return new Promise((resolve) => {
                        const xhrRequest = new XMLHttpRequest();
                        xhrRequest.addEventListener('load', () => {
                            console.log('[universal/service-worker.ts] response.status:', xhrRequest.status);
                            resolve(xhrRequest.response)
                        })
                        xhrRequest.open('GET', 'fixtures/testfile?test=hello1');
                        xhrRequest.send();
                    })

                })
                .then(res => {
                    console.log('[universal/service-worker.ts] response is:', res);
                    // assert.equal(res.success, true);
                    // assert.equal(res.queryValue, "hello1");
                    done();
                })
                .catch((error) => {
                    console.error('[universal/service-worker.ts] response error is', error)
                    done();
                });
        });


    });


    // it.only("Should successfully open an indexedDB database", function() {
    //     this.timeout(50000);
    //     return navigator.serviceWorker
    //         .register("/fixtures/exec-worker.js")
    //         .then(reg => {
    //             return waitUntilWorkerIsActivated(reg.installing!);
    //         })
    //         .then(worker => {
    //             return execInWorker(
    //                 worker,
    //                 `
    //         return new Promise((fulfill,reject) => {
    //             try {
    //                 console.log("do open")
    //                 var openRequest = indexedDB.open("testDB",1);
    //                 console.log("request successful")
    //                 openRequest.onsuccess = () => {
    //                     // fulfill(true)
    //                 };
    //                 openRequest.onerror = (err) => {
    //                     reject(err)
    //                 };
    //             } catch (err) {
    //                 console.log("error caught");
    //                 reject(err)
    //             }
    //         })
    //         `
    //             );
    //         })
    //         .then(returnValue => {
    //             assert.equal(returnValue, true);
    //         });
    // });
});
