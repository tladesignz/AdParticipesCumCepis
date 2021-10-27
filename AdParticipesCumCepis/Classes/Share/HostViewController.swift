//
//  HostViewController.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 26.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

open class HostViewController: ShareViewController
{

    @IBOutlet weak override var stopSharingLb: UILabel! {
        didSet {
            stopSharingLb.text = NSLocalizedString("Don't send Content Security Policy header (allows your website to use third-party resources)", comment: "")
        }
    }

    @IBOutlet weak override var stopSharingSw: UISwitch! {
        didSet {
            stopSharingSw.isEnabled = true
            stopSharingSw.isOn = false
        }
    }


    open override func viewDidLoad() {
        super.viewDidLoad()

        addressLbTextWithPrivateKey = NSLocalizedString(
            "Anyone with this address and private key can visit your website using the Tor Browser:",
            comment: "")

        addressLbTextNoPrivateKey = NSLocalizedString(
            "Anyone with this address can visit your website using the Tor Browser:",
            comment: "")

        navigationItem.title = NSLocalizedString("Website", comment: "")
    }


    // MARK: WebServerDelegate

    public override var mode: WebServer.Mode {
        return .host
    }

    public override var templateName: String {
        return "listing"
    }

    public override var useCsp: Bool {
        return DispatchQueue.main.sync {
            return !stopSharingSw.isOn
        }
    }
}
