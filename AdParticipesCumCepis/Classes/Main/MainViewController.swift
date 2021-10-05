//
//  MainViewController.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 05.10.21.
//

import UIKit

open class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Cepa Participes", comment: "")
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
}
