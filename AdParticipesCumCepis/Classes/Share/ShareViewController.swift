//
//  ShareViewController.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 06.10.21.
//  Copyright (c) 2021 Benjamin Erhart. All rights reserved.
//

import UIKit
import TLPhotoPicker
import Photos

open class ShareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TLPhotosPickerViewControllerDelegate {

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var stopSharingLb: UILabel! {
        didSet {
            stopSharingLb.text = NSLocalizedString("Stop sharing after files have been sent (uncheck to allow downloading individual files)", comment: "")
        }
    }

    @IBOutlet weak var stopSharingSw: UISwitch!

    @IBOutlet weak var publicServiceLb: UILabel! {
        didSet {
            publicServiceLb.text = NSLocalizedString("This is a public service (disables private key)", comment: "")
        }
    }

    @IBOutlet weak var publicServiceSw: UISwitch!

    @IBOutlet weak var customTitleTv: UITextField! {
        didSet {
            customTitleTv.placeholder = NSLocalizedString("Custom title", comment: "")
        }
    }

    @IBOutlet weak var startSharingBt: UIButton! {
        didSet {
            startSharingBt.setTitle(NSLocalizedString("Start sharing", comment: ""), for: .normal)
            startSharingBt.isEnabled = false
        }
    }

    open var assets = [TLPHAsset]()


    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Share", comment: "")

        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(add))
    }


    // MARK: Actions

    @IBAction public func start() {
        print("Start!")
    }

    @objc public func add() {
        let vc = TLPhotosPickerViewController()
        vc.delegate = self

        present(vc, animated: true, completion: nil)
    }


    // MARK: UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let asset = assets[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "asset")
            ?? UITableViewCell(style: .default, reuseIdentifier: "asset")

        cell.textLabel?.text = asset.originalFileName

        if let phAsset = asset.phAsset {
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = false
            options.version = .current

            PHImageManager.default().requestImage(
                for: phAsset, targetSize: CGSize(width: 160, height: 160),
                   contentMode: .aspectFit, options: options)
            { image, info in
                cell.imageView?.image = image
            }
        }

        return cell
    }


    // MARK: TLPhotosPickerViewControllerDelegate

    public func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        assets = withTLPHAssets

        tableView.reloadData()

        startSharingBt.isEnabled = !assets.isEmpty

        return true
    }
}
