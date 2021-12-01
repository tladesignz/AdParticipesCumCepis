//
//  MainViewController.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 05.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI

open class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
                                BridgesConfDelegate
{
    @IBOutlet weak var tableView: UITableView!

    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Ad Participes cum Cepis", comment: "")

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "network.badge.shield.half.filled", in: Bundle.adParticipesCumCepis, compatibleWith: nil),
            style: .plain, target: self, action: #selector(changeBridges))
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Deselect items after return.
        for indexPath in tableView.indexPathsForSelectedRows ?? [] {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }


    // MARK: UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "options")
            ?? UITableViewCell(style: .default, reuseIdentifier: "options")

        switch indexPath.row {
        case 1:
            cell.textLabel?.text = NSLocalizedString("Host a Website", comment: "")

        default:
            cell.textLabel?.text = NSLocalizedString("Share Files", comment: "")
        }

        cell.accessoryType = .disclosureIndicator

        return cell
    }


    // MARK: UITableViewDelegate

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            return
        }

        let vc: UIViewController

        switch indexPath.row {
        case 1:
            vc = Router.host()

        default:
            vc = Router.share()
        }

        navigationController?.pushViewController(vc, animated: true)
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
        // Nothing to do. No Tor currently running here and config already stored.
    }


    // MARK: Actions

    @objc
    open func changeBridges() {
        let vc = BridgesConfViewController()
        vc.delegate = self

        let navC = UINavigationController(rootViewController: vc)
        navC.modalPresentationStyle = .popover
        navC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem

        present(navC, animated: true)
    }
}
