//
//  ReceiveViewController.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 27.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

open class ReceiveViewController: ShareViewController
{

    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Receive Files", comment: "")
    }


    // MARK: WebServerDelegate

    public override var mode: WebServer.Mode {
        return .receive
    }

    public override var templateName: String {
        return "receive"
    }

    public override func context(for item: Item?) -> [String : Any] {
        var context = [String: Any]()

        DispatchQueue.main.sync {
            context["title"] = customTitleTf.text ?? ""
        }

        return context
    }
}
