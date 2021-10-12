//
//  TorManager.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 06.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import Tor

class TorManager {

    private enum Errors: Error {
        case cookieUnreadable
    }

    static let shared = TorManager()

    static let localhost = "127.0.0.1"

    static let torProxyPort: UInt16 = 39050
    static let dnsPort: UInt16 = 39053
    static let webServerPort: UInt = 8080

    private static let torControlPort: UInt16 = 39060

    public lazy var serviceDir: URL? = {
        guard let args = torConf.arguments,
              let i = args.firstIndex(of: "--HiddenServiceDir"),
              i + 1 < args.count && !args[i + 1].isEmpty
        else {
            return nil
        }

        return URL(fileURLWithPath: args[i + 1])
    }()

    public lazy var onionAuth: TorOnionAuth? = {
        guard let url = serviceDir else {
            return nil
        }

        let pubKeyDir = url.appendingPathComponent("authorized_clients", isDirectory: true)

        // Try to create the public key directory, if it doesn't exist, yet.
        // Tor will do that on first start, but then we would need to restart
        // to make it load the key.
        // However, we need to be careful with access flags, because
        // otherwise Tor will complain and reject its use.
        try? FileManager.default.createSecureDirIfNotExists(at: pubKeyDir)

        return TorOnionAuth(privateDirUrl: url, andPublicDirUrl: url)
    }()

    public lazy var serviceUrl: URL? = {
        guard let url = serviceDir?.appendingPathComponent("hostname"),
              let hostname = try? String(contentsOf: url).trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            return nil
        }

        var urlc = URLComponents()
        urlc.host = hostname
        urlc.scheme = "http"

        return urlc.url
    }()


    private var torThread: TorThread?

    private lazy var torConf: TorConfiguration = {
        let conf = TorConfiguration()

        conf.options = ["DNSPort": "\(TorManager.localhost):\(TorManager.dnsPort)",
                        "AutomapHostsOnResolve": "1",
                        "Log": "notice stdout",
                        "LogMessageDomains": "1",
                        "SafeLogging": "0",
                        "SocksPort": "\(TorManager.localhost):\(TorManager.torProxyPort)",
                        "ControlPort": "\(TorManager.localhost):\(TorManager.torControlPort)",
                        "HiddenServicePort": "80 \(TorManager.localhost):\(TorManager.webServerPort)",
                        "AvoidDiskWrites": "1"]

        conf.cookieAuthentication = true

        // Store data in <appdir>/Library/Caches/tor (Library/Caches/ is for things that can persist between
        // launches -- which we'd like so we keep descriptors & etc -- but don't need to be backed up because
        // they can be regenerated by the app)
        if let dataDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("tor", isDirectory: true) {

            log("dataDir=\(dataDir)")

            // Create tor data directory if it does not yet exist.
            try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)

            conf.dataDirectory = dataDir

            // Tor will create that directory by itself.
            let webDir = dataDir.appendingPathComponent("web", isDirectory: true)

            // Need to use #arguments instead of #options because order is important.
            conf.arguments.append("--HiddenServiceDir")
            conf.arguments.append(webDir.path)
        }

        conf.arguments += [
            "--allow-missing-torrc",
            "--ignore-missing-torrc",
        ]

        return conf
    }()

    private var torController: TorController?

    private var torRunning: Bool {
        guard torThread?.isExecuting ?? false else {
            return false
        }

        if let lock = torConf.dataDirectory?.appendingPathComponent("lock") {
            return FileManager.default.fileExists(atPath: lock.path)
        }

        return false
    }

    private var cookie: Data? {
        if let cookieUrl = torConf.dataDirectory?.appendingPathComponent("control_auth_cookie") {
            return try? Data(contentsOf: cookieUrl)
        }

        return nil
    }

    private lazy var controllerQueue = DispatchQueue.global(qos: .userInitiated)


    private init() {
    }

    func start(_ progressCallback: @escaping (Int) -> Void,
               _ completion: @escaping (Error?) -> Void)
    {
        if !torRunning {
            torThread = TorThread(configuration: self.torConf)
            torThread?.start()
        }

        controllerQueue.asyncAfter(deadline: .now() + 0.65) {
            if self.torController == nil {
                self.torController = TorController(
                    socketHost: TorManager.localhost,
                    port: TorManager.torControlPort)
            }

            if !(self.torController?.isConnected ?? false) {
                do {
                    try self.torController?.connect()
                }
                catch let error {
                    return completion(error)
                }
            }

            guard let cookie = self.cookie else {
                return completion(Errors.cookieUnreadable)
            }

            self.torController?.authenticate(with: cookie) { success, error in
                if let error = error {
                    return completion(error)
                }

                var progressObs: Any?
                progressObs = self.torController?.addObserver(forStatusEvents: {
                    (type, severity, action, arguments) -> Bool in

                    if type == "STATUS_CLIENT" && action == "BOOTSTRAP" {
                        let progress = Int(arguments!["PROGRESS"]!)!

                        progressCallback(progress)

                        if progress >= 100 {
                            self.torController?.removeObserver(progressObs)
                        }

                        return true
                    }

                    return false
                })

                var observer: Any?
                observer = self.torController?.addObserver(forCircuitEstablished: { established in
                    guard established else {
                        return
                    }

                    self.torController?.removeObserver(observer)

                    completion(nil)
                })
            }
        }
    }

    func stop() {
        torController?.disconnect()
        torController = nil

        torThread?.cancel()
        torThread = nil
    }

    func getCircuits(_ completion: @escaping ([TorCircuit]) -> Void) {
        torController?.getCircuits(completion)
    }

    func close(_ circuits: [TorCircuit], _ completion: ((Bool) -> Void)?) {
        torController?.close(circuits, completion: completion)
    }

    private func log(_ message: String) {
        print("[\(String(describing: type(of: self)))] \(message)")
    }
}
