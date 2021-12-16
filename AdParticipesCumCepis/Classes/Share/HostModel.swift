//
//  HostModel.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 16.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

public class HostModel: ShareModel {

    public override var title: String {
        NSLocalizedString("Website", comment: "")
    }

    public override var addressLbTextWithPrivateKey: String {
        NSLocalizedString(
            "Anyone with this address and private key can visit your website using the Tor Browser:",
            comment: "")
    }

    public override var addressLbTextNoPrivateKey: String {
        NSLocalizedString(
            "Anyone with this address can visit your website using the Tor Browser:",
            comment: "")
    }

    public override var stopSharingAfterSendLb: String {
        NSLocalizedString(
            "Don't send Content Security Policy header (allows your website to use third-party resources)",
            comment: "")
    }

    public override var stopSharingAfterSendInitialValue: Bool {
        false
    }


    // MARK: WebServerDelegate

    public override var mode: WebServer.Mode {
        return .host
    }

    public override var templateName: String {
        return "listing"
    }

    public override var useCsp: Bool {
        stopSharingAfterSend
    }
}
