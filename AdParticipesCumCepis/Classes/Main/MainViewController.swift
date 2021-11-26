//
//  MainViewController.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 05.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

open class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Ad Participes cum Cepis", comment: "")
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
        return 3
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "options")
            ?? UITableViewCell(style: .default, reuseIdentifier: "options")

        switch indexPath.row {
        case 1:
            cell.textLabel?.text = NSLocalizedString("Receive Files", comment: "")

        case 2:
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
            vc = Router.receive()

        case 2:
            vc = Router.host()

        default:
            vc = Router.share()
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}
