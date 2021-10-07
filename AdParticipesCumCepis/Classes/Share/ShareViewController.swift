//
//  ShareViewController.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 06.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit
import TLPhotoPicker
import Photos
import MBProgressHUD
import GCDWebServer

open class ShareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
                                    TLPhotosPickerViewControllerDelegate
{

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var startContainer: UIView!


    @IBOutlet weak var stopSharingLb: UILabel! {
        didSet {
            stopSharingLb.text = NSLocalizedString("Stop sharing after files have been sent (uncheck to allow downloading individual files)", comment: "")
        }
    }

    @IBOutlet weak var stopSharingSw: UISwitch! {
        didSet {
            // TODO: Add support.
            stopSharingSw.isOn = false
            stopSharingSw.isEnabled = false
        }
    }

    @IBOutlet weak var publicServiceLb: UILabel! {
        didSet {
            publicServiceLb.text = NSLocalizedString("This is a public service (disables private key)", comment: "")
        }
    }

    @IBOutlet weak var publicServiceSw: UISwitch! {
        didSet {
            // TODO: Add support.
            publicServiceSw.isOn = true
            publicServiceSw.isEnabled = false
        }
    }

    @IBOutlet weak var customTitleTf: UITextField! {
        didSet {
            customTitleTf.placeholder = NSLocalizedString("Custom title", comment: "")

            // TODO: Add support.
            customTitleTf.isEnabled = false
        }
    }

    @IBOutlet weak var startSharingBt: UIButton! {
        didSet {
            startSharingBt.setTitle(NSLocalizedString("Start sharing", comment: ""), for: .normal)

            // TODO: Add support for actual file sharing.
//            startSharingBt.isEnabled = false
        }
    }

    @IBOutlet weak var stopContainer: UIView!

    @IBOutlet weak var addressLb: UILabel!

    @IBOutlet weak var address: UILabel!

    @IBOutlet weak var copyAddressBt: UIButton!

    @IBOutlet weak var qrAddressBt: UIButton!

    @IBOutlet weak var keyLb: UILabel! {
        didSet {
            keyLb.text = NSLocalizedString("Private key:", comment: "")
        }
    }

    @IBOutlet weak var key: UILabel!

    @IBOutlet weak var copyKeyBt: UIButton!

    @IBOutlet weak var qrKeyBt: UIButton!

    @IBOutlet weak var stopSharingBt: UIButton! {
        didSet {
            stopSharingBt.setTitle(NSLocalizedString("Stop sharing", comment: ""), for: .normal)
        }
    }


    open var assets = [TLPHAsset]()


    private lazy var hud: MBProgressHUD = {
        let hud = MBProgressHUD(view: view)

        hud.mode = .determinate

        hud.label.text = NSLocalizedString("Starting Tor…", comment: "")

        view.addSubview(hud)

        return hud
    }()

    private lazy var webServer: GCDWebServer =  {
        let webServer = GCDWebServer()

        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { _ in
            return GCDWebServerDataResponse(html: "<html><body><p>Hello World</p></body></html>")
        }

        return webServer
    }()


    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Share", comment: "")

        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(add))
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if webServer.isRunning {
            stop()
        }
    }


    // MARK: Actions

    @objc public func add() {
        let vc = TLPhotosPickerViewController()
        vc.delegate = self

        present(vc, animated: true, completion: nil)
    }

    @IBAction public func start() {
        hud.show(animated: true)

        do {
            try webServer.start(options: [
                GCDWebServerOption_Port: TorManager.webServerPort,
                GCDWebServerOption_AutomaticallySuspendInBackground: false])
        }
        catch {
            hud.label.text = error.localizedDescription

            hud.hide(animated: true, afterDelay: 3)

            return
        }

        TorManager.shared.start { progress in
            DispatchQueue.main.async {
                self.hud.progress = Float(progress) / 100
            }
        } _: { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.hud.mode = .text
                    self.hud.label.text = error.localizedDescription

                    self.hud.hide(animated: true, afterDelay: 3)

                    return
                }

                self.address.text = TorManager.shared.hostname

                if self.publicServiceSw.isOn {
                    self.addressLb.text = NSLocalizedString("Anyone with this address can download your files using the Tor Browser:", comment: "")
                    self.keyLb.isHidden = true
                    self.key.superview?.isHidden = true
                    self.copyKeyBt.isHidden = true
                    self.qrKeyBt.isHidden = true
                }
                else {
                    self.addressLb.text = NSLocalizedString("Anyone with this address and private key can download your files using the Tor Browser:", comment: "")
                    self.keyLb.isHidden = false
                    self.key.superview?.isHidden = false
                    self.copyKeyBt.isHidden = false
                    self.qrKeyBt.isHidden = false
                }

                self.hud.hide(animated: true, afterDelay: 0.5)

                self.stopContainer.layer.opacity = 0
                self.stopContainer.isHidden = false

                UIView.animate(withDuration: 0.5) {
                    self.startContainer.layer.opacity = 0
                    self.stopContainer.layer.opacity = 1
                } completion: { _ in
                    self.startContainer.isHidden = true
                    self.startContainer.layer.opacity = 1
                }
            }
        }
    }

    @IBAction public func stop() {
        TorManager.shared.stop()

        webServer.stop()

        startContainer.layer.opacity = 0
        startContainer.isHidden = false

        UIView.animate(withDuration: 0.5) {
            self.startContainer.layer.opacity = 1
            self.stopContainer.layer.opacity = 0
        } completion: { _ in
            self.stopContainer.isHidden = true
            self.stopContainer.layer.opacity = 1
        }
    }

    @IBAction public func copy2Clipboard(_ sender: UIButton) {
        switch sender {
        case copyAddressBt:
            UIPasteboard.general.string = address.text

        default:
            UIPasteboard.general.string = key.text
        }
    }

    @IBAction public func showQrCode(_ sender: UIButton) {
        let vc = Router.showQr()

        switch sender {
        case qrAddressBt:
            vc.qrCode = address.text ?? ""

        default:
            vc.qrCode = key.text ?? ""
        }

        let navC = UINavigationController(rootViewController: vc)

        present(navC, animated: true)
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
