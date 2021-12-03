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

class TorManager {

    private enum Errors: Error {
        case cookieUnreadable
        case noSocksAddr
    }

    static let shared = TorManager()

    static let localhost = "127.0.0.1"

    static let webServerPort: UInt = 8080

    public lazy var onionAuth: TorOnionAuth? = {
        guard let url = FileManager.default.pubKeyDir else {
            return nil
        }

        return TorOnionAuth(withPrivateDir: nil, andPublicDir: url)
    }()

    public lazy var serviceUrl: URL? = {
        guard let url = FileManager.default.serviceDir?.appendingPathComponent("hostname"),
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

    private var torConf: TorConfiguration?

    private var torController: TorController?

    private var torRunning: Bool {
        (torThread?.isExecuting ?? false) && (torConf?.isLocked ?? false)
    }

    private lazy var controllerQueue = DispatchQueue.global(qos: .userInitiated)

    private var ipStatus = IpSupport.Status.unavailable


    private init() {
        IpSupport.shared.start({ [weak self] status in
            self?.ipStatus = status

            if (self?.torRunning ?? false) && (self?.torController?.isConnected ?? false) {
                self?.torController?.setConfs(status.torConf(Settings.transport, Transport.asConf))
                { success, error in
                    if let error = error {
                        print("[\(String(describing: type(of: self)))] error: \(error)")
                    }

                    self?.torController?.resetConnection()
                }
            }
        })
    }

    func start(_ progressCallback: @escaping (Int) -> Void,
               _ completion: @escaping (Error?, _ socksAddr: String?) -> Void)
    {
        Settings.transport.start()

        if !torRunning {
            // Create fresh - transport ports may have changed.
            torConf = createTorConf()
//            print(torConf!.compile())

            torThread = TorThread(configuration: torConf)
            torThread?.start()
        }

        controllerQueue.asyncAfter(deadline: .now() + 0.65) {
            if self.torController == nil, let cpf = self.torConf?.controlPortFile {
                self.torController = TorController(controlPortFile: cpf)
            }

            if !(self.torController?.isConnected ?? false) {
                do {
                    try self.torController?.connect()
                }
                catch let error {
                    return completion(error, nil)
                }
            }

            guard let cookie = self.torConf?.cookie else {
                return completion(Errors.cookieUnreadable, nil)
            }

            self.torController?.authenticate(with: cookie) { success, error in
                if let error = error {
                    return completion(error, nil)
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

                    self.torController?.getInfoForKeys(["net/listeners/socks"]) { response in
                        guard let socksAddr = response.first, !socksAddr.isEmpty else {
                            return completion(Errors.noSocksAddr, nil)
                        }

                        completion(nil, socksAddr)
                    }
                })
            }
        }
    }

    func stop() {
        Settings.transport.stop()

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

    private func createTorConf() -> TorConfiguration {
        let conf = TorConfiguration()
        conf.ignoreMissingTorrc = true
        conf.cookieAuthentication = true
        conf.autoControlPort = true
        conf.avoidDiskWrites = true
        conf.dataDirectory = FileManager.default.torDir
        conf.hiddenServiceDirectory = FileManager.default.serviceDir

        let transport = Settings.transport

        conf.arguments += transport.torConf(Transport.asArguments).joined()

        conf.arguments += ipStatus.torConf(transport, Transport.asArguments).joined()

        conf.options = ["Log": "notice stdout",
                        "LogMessageDomains": "1",
                        "SafeLogging": "0",
                        "SocksPort": "auto",
                        "HiddenServicePort": "80 \(TorManager.localhost):\(TorManager.webServerPort)",
                        "UseBridges": transport == .none ? "0" : "1"]

        return conf
    }

    private func log(_ message: String) {
        print("[\(String(describing: type(of: self)))] \(message)")
    }
}
