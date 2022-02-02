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

    public func makeUIViewController(context: Context) -> some UIViewController {
        UINavigationController(rootViewController: vc)
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(vc)
    }

    public class Coordinator: BridgesConfDelegate {

        init(_ vc: BridgesConfViewController) {
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
    }
}
