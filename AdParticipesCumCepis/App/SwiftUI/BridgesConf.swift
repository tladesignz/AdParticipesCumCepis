//
//  BridgesConf.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 17.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import SwiftUI
import IPtProxyUI

public struct BridgesConf: UIViewControllerRepresentable {

    public let vc = BridgesConfViewController()

    public let completion: (() -> Void)?


    public init(_ completion: (() -> Void)? = nil) {
        self.completion = completion
    }


    public func makeUIViewController(context: Context) -> some UIViewController {
        UINavigationController(rootViewController: vc)
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(vc, completion)
    }

    public class Coordinator: BridgesConfDelegate {

        public let completion: (() -> Void)?


        init(_ vc: BridgesConfViewController, _ completion: (() -> Void)?) {
            self.completion = completion

            vc.delegate = self
        }


        // MARK: BridgesConfDelegate

        open var transport: Transport {
            get {
                Settings.transport
            }
            set {
                Settings.transport = newValue
            }
        }

        open var customBridges: [String]? {
            get {
                Settings.customBridges
            }
            set {
                Settings.customBridges = newValue
            }
        }

        open func save() {
            TorManager.shared.reconfigureBridges()
        }


        deinit {
            completion?()
        }
    }
}
