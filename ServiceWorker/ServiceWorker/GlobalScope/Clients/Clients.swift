import Foundation
import JavaScriptCore
import PromiseKit

@objc protocol ClientsExports: JSExport {
    func get(_: String) -> JSValue?
    func matchAll(_: [String: Any]?) -> JSValue?
    func openWindow(_: String) -> JSValue?
    func claim() -> JSValue?
}

/// Implementation of Clients: https://developer.mozilla.org/en-US/docs/Web/API/Clients to allow
/// Service Workers to get/take control of/open clients under their scope. This is really just
/// a bridge to whatever ServiceWorkerClientDelegate is set.
@objc class Clients: NSObject, ClientsExports {

    unowned let worker: ServiceWorker

    init(for worker: ServiceWorker) {
        self.worker = worker
    }

    func get(_ id: String) -> JSValue? {

        return Promise<Client?> { resolver in
            if self.worker.clientsDelegate?.clients?(self.worker, getById: id, { err, clientProtocol in
                if let error = err {
                    resolver.reject(error)
                } else if let clientExists = clientProtocol {
                    resolver.fulfill(Client.getOrCreate(from: clientExists))
                } else {
                    resolver.fulfill(nil)
                }
            }) == nil {
                resolver.reject(ErrorMessage("ServiceWorkerDelegate does not implement get()"))
            }
        }.toJSPromiseInCurrentContext()
    }

    func matchAll(_ options: [String: Any]?) -> JSValue? {

        return Promise<[Client]> { resolver in

            // Two options provided here: https://developer.mozilla.org/en-US/docs/Web/API/Clients/matchAll

            let type = options?["type"] as? String ?? "all"
            let includeUncontrolled = options?["includeUncontrolled"] as? Bool ?? false

            let options = ClientMatchAllOptions(includeUncontrolled: includeUncontrolled, type: type)

            if self.worker.clientsDelegate?.clients?(self.worker, matchAll: options, { err, clientProtocols in
                if let error = err {
                    resolver.reject(error)
                } else if let clientProtocolsExist = clientProtocols {
                    let mapped = clientProtocolsExist.map({ Client.getOrCreate(from: $0) })
                    resolver.fulfill(mapped)
                } else {
                    resolver.reject(ErrorMessage("Callback did not error but did not send a response either"))
                }
            }) == nil {
                resolver.reject(ErrorMessage("ServiceWorkerDelegate does not implement matchAll()"))
            }
        }
        .toJSPromiseInCurrentContext()
    }

    func openWindow(_ url: String) -> JSValue? {

        return Promise<ClientProtocol> { resolver in
            guard let parsedURL = URL(string: url, relativeTo: self.worker.url) else {
                return resolver.reject(ErrorMessage("Could not parse URL given"))
            }

            if self.worker.clientsDelegate?.clients?(self.worker, openWindow: parsedURL, { err, resp in
                if let error = err {
                    resolver.reject(error)
                } else if let response = resp {
                    resolver.fulfill(response)
                }
            }) == nil {
                resolver.reject(ErrorMessage("ServiceWorkerDelegate does not implement openWindow()"))
            }
        }.toJSPromiseInCurrentContext()
    }

    func claim() -> JSValue? {

        return Promise<Void> { resolver in
            if self.worker.clientsDelegate?.clientsClaim?(self.worker, { err in
                if let error = err {
                    resolver.reject(error)
                } else {
                    resolver.fulfill(())
                }
            }) == nil {
                resolver.reject(ErrorMessage("ServiceWorkerDelegate does not implement claim()"))
            }
        }.toJSPromiseInCurrentContext()
    }
}
