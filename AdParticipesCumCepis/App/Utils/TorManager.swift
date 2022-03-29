//
//  TorManager.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 06.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import Tor
import IPtProxyUI

open class TorManager {

    /**
     - parameter error: If an error happend, all other values will be `nil`.
     - parameter serviceUrl: The URL of the freshly started service.
     - parameter privateKey: The generated private key, if `isPublic` was set to false.
     */
    public typealias Completion = (_ error: Error?, _ serviceUrl: URL?, _ privateKey: String?) -> Void

    private enum Errors: Error {
        case cookieUnreadable
        case noSocksAddr
    }

    public static let shared = TorManager()

    public static let localhost = "127.0.0.1"

    public static let webServerPort: UInt = 8080

    public var connected: Bool {
        (torThread?.isExecuting ?? false)
        && (torConf?.isLocked ?? false)
        && (torController?.isConnected ?? false)
    }


    private var torThread: TorThread?

    private var torConf: TorConfiguration?

    private var torController: TorController?

    private lazy var controllerQueue = DispatchQueue.global(qos: .userInitiated)

    private var ipStatus = IpSupport.Status.unavailable

    private var services = Set<String>()


    private init() {
        IpSupport.shared.start({ [weak self] status in
            self?.ipStatus = status

            if (self?.connected ?? false) && (self?.torController?.isConnected ?? false) {
                self?.torController?.setConfs(status.torConf(Settings.transport, Transport.asConf))
                { success, error in
                    if let error = error {
                        self?.log(error.localizedDescription)
                    }

                    self?.torController?.resetConnection()
                }
            }
        })
    }


    // MARK: Public Methods

    /**
     Start an Onion service, if it isn't yet.

     Will start Tor, if it isn't, yet.

     - parameter name: The service name. Used as folder name and identifier to distinguish internally.
     - parameter isPublic: Flag, if service shall be public. If false, will create a public/private key pair for access control.
     - parameter progressCallback: Will be called, in case Tor needs to start up and will be informed about that progress.
     - parameter completion: Callback, when everything is ready.
     */
    open func start(for name: String, _ isPublic: Bool, _ progressCallback: @escaping (Int) -> Void,
                    _ completion: @escaping Completion)
    {
        // Ignore, if this service is already started.
        guard services.insert(name).inserted else {
            return
        }

        // Remove old service configuration.
        removeServiceDir(for: name)

        // Trigger recreation of directories.
        _ = pubKeyDir(for: name)

        var privateKey: String? = nil

        if !isPublic {
            // Create a new key pair.
            let keypair = TorX25519KeyPair()

            // Private key needs to be shown to the user.
            privateKey = keypair.privateKey

            // The public key is needed by the onion service, *before* start.
            if let publicKey = keypair.getPublicAuthKey(withName: "share") {
                onionAuth(for: name)?.set(publicKey)
            }
        }

        // If Tor is already running, just reconfigure services.
        if connected {
            torController?.setConfs(serviceConf(Transport.asConf)) { [weak self] _, error in
                if let error = error {
                    return completion(error, nil, nil)
                }

                self?.complete(for: name, privateKey, completion)
            }

            return
        }

        // If not (fully) started, (re-)try.

        Settings.transport.start()

        // Create fresh - transport ports may have changed.
        torConf = createTorConf()
//        log(torConf!.compile().debugDescription)

        torThread?.cancel()
        torThread = TorThread(configuration: torConf)
        torThread?.start()

        controllerQueue.asyncAfter(deadline: .now() + 0.65) { [weak self] in
            if self?.torController == nil, let cpf = self?.torConf?.controlPortFile {
                self?.torController = TorController(controlPortFile: cpf)
            }

            if !(self?.torController?.isConnected ?? false) {
                do {
                    try self?.torController?.connect()
                }
                catch let error {
                    return completion(error, nil, nil)
                }
            }

            guard let cookie = self?.torConf?.cookie else {
                return completion(Errors.cookieUnreadable, nil, nil)
            }

            self?.torController?.authenticate(with: cookie) { success, error in
                if let error = error {
                    return completion(error, nil, nil)
                }

                var progressObs: Any?
                progressObs = self?.torController?.addObserver(forStatusEvents: {
                    (type, severity, action, arguments) -> Bool in

                    if type == "STATUS_CLIENT" && action == "BOOTSTRAP" {
                        let progress = Int(arguments!["PROGRESS"]!)!

                        progressCallback(progress)

                        if progress >= 100 {
                            self?.torController?.removeObserver(progressObs)
                        }

                        return true
                    }

                    return false
                })

                var observer: Any?
                observer = self?.torController?.addObserver(forCircuitEstablished: { established in
                    guard established else {
                        return
                    }

                    self?.torController?.removeObserver(observer)

                    self?.complete(for: name, privateKey, completion)
                })
            }
        }
    }

    /**
     Will stop the Onion service with the given name.

     Will stop Tor, if that was the last service to stop.

     - parameter name: The name of the service to stop.
     */
    open func stop(for name: String) {
        // Ignore, if this service is already stopped.
        guard services.remove(name) != nil else {
            return
        }

        // If Tor needs to continue running, just reconfigure services.
        if !services.isEmpty {
            torController?.setConfs(serviceConf(Transport.asConf)) { [weak self] _, error in
                if let error = error {
                    self?.log(error.localizedDescription)
                }

                self?.removeServiceDir(for: name)
            }

            return
        }

        // If not needed anymore, stop Tor.

        Settings.transport.stop()

        torController?.disconnect()
        torController = nil

        torThread?.cancel()
        torThread = nil

        removeServiceDir(for: name)
    }

    /**
     Will reconfigure Tor with changed bridge configuration, if it is already running.

     ATTENTION: If Tor is currently starting up, nothing will change.
     */
    open func reconfigureBridges() {
        guard connected else {
            return // Nothing can be done. Will get configured on (next) start.
        }

        torController?.resetConf(forKey: "UseBridges")
        { [weak self] _, error in
            if let error = error {
                self?.log(error.localizedDescription)

                return
            }

            self?.torController?.resetConf(forKey: "ClientTransportPlugin")
            { _, error in
                if let error = error {
                    self?.log(error.localizedDescription)

                    return
                }

                self?.torController?.resetConf(forKey: "Bridge")
                { _, error in
                    if let error = error {
                        self?.log(error.localizedDescription)

                        return
                    }

                    switch Settings.transport {
                    case .obfs4, .custom:
                        Transport.snowflake.stop()

                    case .snowflake, .snowflakeAmp:
                        Transport.obfs4.stop()

                    default:
                        Transport.obfs4.stop()
                        Transport.snowflake.stop()
                    }

                    guard Settings.transport != .none else {
                        return
                    }

                    Settings.transport.start()

                    var conf = Settings.transport.torConf(Transport.asConf)
                    conf.append(Transport.asConf(key: "UseBridges", value: "1"))

//                    self?.log(conf.debugDescription)

                    self?.torController?.setConfs(conf)
                }
            }
        }
    }

    open func getCircuits(_ completion: @escaping ([TorCircuit]) -> Void) {
        torController?.getCircuits(completion)
    }

    open func close(_ circuits: [TorCircuit], _ completion: ((Bool) -> Void)?) {
        torController?.close(circuits, completion: completion)
    }


    // MARK: Private Methods

    private func createTorConf() -> TorConfiguration {
        let conf = TorConfiguration()
        conf.ignoreMissingTorrc = true
        conf.cookieAuthentication = true
        conf.autoControlPort = true
        conf.avoidDiskWrites = true
        conf.dataDirectory = FileManager.default.torDir

        let transport = Settings.transport

        conf.arguments += transport.torConf(Transport.asArguments).joined()

        conf.arguments += ipStatus.torConf(transport, Transport.asArguments).joined()

        conf.arguments += serviceConf(Transport.asArguments).joined()

        conf.options = ["Log": "notice stdout",
                        "LogMessageDomains": "1",
                        "SafeLogging": "0",
                        "SocksPort": "auto",
                        "UseBridges": transport == .none ? "0" : "1"]

        return conf
    }

    private func serviceDir(for name: String) -> URL? {
        return FileManager.default.torDir?.appendingPathComponent(name, isDirectory: true)
    }

    private func pubKeyDir(for name: String) -> URL? {
        guard let url = serviceDir(for: name)?.appendingPathComponent("authorized_clients", isDirectory: true) else {
            return nil
        }

        // Try to create the public key directory, if it doesn't exist, yet.
        // Tor will do that on first start, but then we would need to restart
        // to make it load the key.
        // However, we need to be careful with access flags, because
        // otherwise Tor will complain and reject its use.
        try? FileManager.default.createSecureDirIfNotExists(at: url)

        return url
    }

    private func onionAuth(for name: String) -> TorOnionAuth? {
        guard let url = pubKeyDir(for: name) else {
            return nil
        }

        return TorOnionAuth(withPrivateDir: nil, andPublicDir: url)
    }

    private func serviceConf<T>(_ cv: (String, String) -> T) -> [T] {
        var conf = [T]()

        for service in services {
            if let serviceDir = serviceDir(for: service) {
                conf.append(cv("HiddenServiceDir", serviceDir.path))
                // Each dir needs at least one of these lines.
                conf.append(cv("HiddenServicePort", "80 \(TorManager.localhost):\(TorManager.webServerPort)"))
            }
        }

//        log(conf.debugDescription)

        return conf
    }

    private func serviceUrl(for name: String) -> URL? {
        guard let url = serviceDir(for: name)?.appendingPathComponent("hostname"),
              let hostname = try? String(contentsOf: url).trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            return nil
        }

        var urlc = URLComponents()
        urlc.host = hostname
        urlc.scheme = "http"

        return urlc.url
    }

    private func complete(for name: String, _ privateKey: String?, _ completion: @escaping Completion) {
        let serviceUrl = self.serviceUrl(for: name)

        if let privateKey = privateKey, let serviceUrl = serviceUrl {
            // After successful start, we should now have a domain.
            // Time to store the private key for debugging or later reuse.
            self.onionAuth(for: name)?.set(TorAuthKey(private: privateKey, forDomain: serviceUrl))
        }

        completion(nil, serviceUrl, privateKey)
    }

    /**
     Remove service dir, in order to make Tor create a new service with a new address the next time.

     - parameter name: The service name.
     */
    private func removeServiceDir(for name: String) {
        if let serviceDir = serviceDir(for: name),
           FileManager.default.fileExists(atPath: serviceDir.path)
        {
            do {
                try FileManager.default.removeItem(at: serviceDir)
            }
            catch {
                log("Can't remove \"\(serviceDir.path)\": \(error)")
            }
        }
    }

    private func log(_ message: String) {
        print("[\(String(describing: type(of: self)))] \(message)")
    }
}
