//
//  MainViewController.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 05.10.21.
//  Copyright (c) 2021 Benjamin Erhart. All rights reserved.
//

import UIKit

open class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Ad Participes cum Cepis", comment: "")
    }


    // MARK: UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "options")
            ?? UITableViewCell(style: .default, reuseIdentifier: "options")

        cell.textLabel?.text = NSLocalizedString("Share Files", comment: "")

        return cell
    }


    // MARK: UITableViewDelegate

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            navigationController?.pushViewController(Router.share(), animated: true)
        }
    }
}
