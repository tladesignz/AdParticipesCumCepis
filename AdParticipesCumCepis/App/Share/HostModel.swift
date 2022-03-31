//
//  HostModel.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 16.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

open class HostModel: ShareModel {

    open override var title: String {
        NSLocalizedString("Host", comment: "")
    }

    open override var addressLbTextWithPrivateKey: String {
        NSLocalizedString(
            "Anyone with this address and private key can visit your website using the Tor Browser:",
            comment: "")
    }

    open override var addressLbTextNoPrivateKey: String {
        NSLocalizedString(
            "Anyone with this address can visit your website using the Tor Browser:",
            comment: "")
    }

    open override var stopSharingAfterSendLb: String {
        NSLocalizedString(
            "Don't send Content Security Policy header (allows your website to use third-party resources)",
            comment: "")
    }

    open override var stopSharingAfterSendInitialValue: Bool {
        false
    }


    // MARK: WebServerDelegate

    open override var mode: WebServer.Mode {
        return .host
    }

    open override var templateName: String {
        return "listing"
    }

    open override var useCsp: Bool {
        stopSharingAfterSend
    }
}
