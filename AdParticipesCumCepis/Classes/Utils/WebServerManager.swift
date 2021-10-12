//
//  WebServerManager.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 12.10.21.
//

import Foundation
import GCDWebServer
import Mustache

protocol WebServerDelegate {

    var templateName: String { get }

    var statusCode: Int { get }

    var data: [String: Any] { get }
}

class WebServerManager {

    static let shared = WebServerManager()


    var delegate: WebServerDelegate? = nil


    private static let defaultData: [String: Any] = [
        "static_url_path": ""]

    private lazy var webServer: GCDWebServer = {
        let webServer = GCDWebServer()

        webServer.addGETHandler(
            forBasePath: "/", directoryPath: Router.bundle.path(forResource: "static", ofType: nil)!,
            indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)

        webServer.addHandler(forMethod: "GET", pathRegex: ".*\\.html", request: GCDWebServerRequest.self) { _ in
            var html = "<html><body><h1>Internal Server Error</h1></body></html>"
            var statusCode = 500

            do {
                let tpl = try Template(named: self.delegate?.templateName ?? "404",
                                       bundle: Router.bundle,
                                       templateExtension: "html", encoding: .utf8)

                var data = WebServerManager.defaultData

                if let dData = self.delegate?.data {
                    data.merge(dData) { $1 }
                }

                html = try tpl.render(data)

                statusCode = self.delegate?.statusCode ?? 404
            }
            catch {
                print("[\(String(describing: type(of: self)))] error: \(error.localizedDescription)")
            }

            let res = GCDWebServerDataResponse(html: html)
            res?.statusCode = statusCode

            return res
        }

        // Redirect request to root directory to "index.html".
        webServer.addHandler(forMethod: "GET", path: "/", request: GCDWebServerRequest.self) {
            return GCDWebServerResponse(redirect: URL(string: "index.html", relativeTo: $0.url)!, permanent: false)
        }

        return webServer
    }()

    func start() throws {
        try webServer.start(options: [
            GCDWebServerOption_Port: TorManager.webServerPort,
            GCDWebServerOption_AutomaticallySuspendInBackground: false])
    }

    func stop() {
        webServer.stop()
    }
}
