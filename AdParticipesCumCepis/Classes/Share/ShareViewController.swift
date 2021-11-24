//
//  ShareViewController.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 06.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit
import TLPhotoPicker
import MBProgressHUD
import Tor
import SwiftUTI

open class ShareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
                                TLPhotosPickerViewControllerDelegate, WebServerDelegate,
                                UIDocumentPickerDelegate
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
            publicServiceSw.isOn = false
        }
    }

    @IBOutlet weak var customTitleTf: UITextField! {
        didSet {
            customTitleTf.placeholder = NSLocalizedString("Custom title", comment: "")
        }
    }

    @IBOutlet weak var startSharingBt: UIButton! {
        didSet {
            startSharingBt.setTitle(NSLocalizedString("Start sharing", comment: ""), for: .normal)
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


    open var addressLbTextWithPrivateKey = NSLocalizedString(
        "Anyone with this address and private key can download your files using the Tor Browser:",
        comment: "")

    open var addressLbTextNoPrivateKey = NSLocalizedString(
        "Anyone with this address can download your files using the Tor Browser:",
        comment: "")

    open var items = [Item]()


    private lazy var hud: MBProgressHUD = {
        let hud = MBProgressHUD(view: view)

        hud.mode = .determinate

        hud.label.text = NSLocalizedString("Starting Tor…", comment: "")

        view.addSubview(hud)

        return hud
    }()

    private var webServer: WebServer? {
        return BaseAppDelegate.shared?.webServer
    }


    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Share", comment: "")

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(addAsset)),
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addDocument))
        ]

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))

        let fm = FileManager.default
        items += fm.contentsOfDirectory(at: fm.docsDir).map { File($0, relativeTo: fm.docsDir) }
    }


    // MARK: Actions

    @objc public func addAsset() {
        let vc = TLPhotosPickerViewController()
        vc.delegate = self

        present(vc, animated: true, completion: nil)
    }

    @objc func addDocument() {
        let vc = UIDocumentPickerViewController(documentTypes: [UTI.item.rawValue], in: .import)
        vc.delegate = self

        present(vc, animated: true)
    }

    @IBAction public func dismissKeyboard() {
        customTitleTf.resignFirstResponder()
    }

    @IBAction public func start() {
        hud.progress = 0
        hud.show(animated: true)

        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }

        do {
            webServer?.delegate = self
            try webServer?.start()
        }
        catch {
            hud.label.text = error.localizedDescription

            hud.hide(animated: true, afterDelay: 3)

            return
        }

        var privateKey: String? = nil

        if publicServiceSw.isOn {
            // Remove all keys, so Tor doesn't encrypt the rendezvous response.
            for i in (0 ..< (TorManager.shared.onionAuth?.keys.count ?? 0)).reversed() {
                TorManager.shared.onionAuth?.removeKey(at: i)
            }
        }
        else if let k = TorManager.shared.onionAuth?.keys.first(where: { $0.isPrivate }) {
            privateKey = k.key
        }
        else {
            // Create a new key pair.
            let keypair = TorX25519KeyPair()

            // Private key needs to be shown to the user.
            privateKey = keypair.privateKey

            // The public key is needed by the onion service, *before* start.
            if let publicKey = keypair.getPublicAuthKey(withName: "share") {
                TorManager.shared.onionAuth?.set(publicKey)
            }
        }

        TorManager.shared.start { progress in
            DispatchQueue.main.async {
                self.hud.progress = Float(progress) / 100
            }
        } _: { error, socksAddr in
            DispatchQueue.main.async {
                if let error = error {
                    self.hud.mode = .text
                    self.hud.label.text = error.localizedDescription

                    self.hud.hide(animated: true, afterDelay: 3)

                    return
                }

                self.address.text = TorManager.shared.serviceUrl?.absoluteString

                if let privateKey = privateKey {
                    // After successful start, we should now have a domain.
                    // Time to store the private key for later reuse.
                    if let url = TorManager.shared.serviceUrl {
                        TorManager.shared.onionAuth?.set(TorAuthKey(private: privateKey, forDomain: url))
                    }

                    self.addressLb.text = self.addressLbTextWithPrivateKey
                    self.key.text = privateKey
                    self.keyLb.isHidden = false
                    self.key.superview?.isHidden = false
                    self.copyKeyBt.isHidden = false
                    self.qrKeyBt.isHidden = false
                }
                else {
                    self.addressLb.text = self.addressLbTextNoPrivateKey
                    self.keyLb.isHidden = true
                    self.key.superview?.isHidden = true
                    self.copyKeyBt.isHidden = true
                    self.qrKeyBt.isHidden = true
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

        webServer?.stop()
        webServer?.delegate = nil

        navigationItem.hidesBackButton = false
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }

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
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "item")
            ?? UITableViewCell(style: .default, reuseIdentifier: "item")

        cell.textLabel?.text = item.basename

        item.getThumbnail { image, info in
            cell.imageView?.image = image
        }

        return cell
    }


    // MARK: UITableViewDelegate

    @available(iOS 11.0, *)
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration?
    {
        let action = UIContextualAction(style: .destructive, title: nil) { (_, _, completion) in
            do {
                let item = self.items[indexPath.row]

                if let item = item as? File {
                    try FileManager.default.removeItem(at: item.url)
                }

                self.items.remove(at: indexPath.row)

                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.endUpdates()

                completion(true)
            }
            catch {
                print(error)

                completion(false)
            }
        }

        if #available(iOS 13.0, *) {
            action.image = UIImage(systemName: "trash.fill")
        }
        else {
            action.title = NSLocalizedString("Delete", comment: "")
        }

        return UISwipeActionsConfiguration(actions: [action])
    }


    // MARK: TLPhotosPickerViewControllerDelegate

    public func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        let offset = items.count

        items += withTLPHAssets.map { Asset($0) }

        tableView.insertRows(at: withTLPHAssets.indices.map { IndexPath(row: offset + $0, section: 0) },
                             with: .automatic)

        startSharingBt.isEnabled = !items.isEmpty

        return true
    }


    // MARK: WebServerDelegate

    public var mode: WebServer.Mode {
        return .share
    }

    public var templateName: String {
        return "send"
    }

    public var useCsp: Bool {
        return true
    }

    public func context(for item: Item?) -> [String : Any] {
        var items = items
        var breadcrumbs = [[String]]()
        var breadcrumbs_leaf = "/"

        if let dir = item as? File, dir.isDir {
            items = dir.children()

            if var pc = dir.relativePath?.components(separatedBy: "/") {
                breadcrumbs_leaf = pc.removeLast()

                breadcrumbs.append(["home", "/"])

                for i in 0 ..< pc.count {
                    breadcrumbs.append([pc[i], "/\(pc[0...i].joined(separator: "/"))/"])
                }
            }
        }

        var context: [String: Any] = [
            "download_individual_files": true,
            "breadcrumbs": breadcrumbs,
            "breadcrumbs_leaf": breadcrumbs_leaf,
            // Always show the total size of *all* files, because *all* files end up in the ZIP file!
            "filesize_human": ByteCountFormatter.string(
                fromByteCount: self.items.reduce(0, { $0 + ($1.size ?? 0) }), countStyle: .file),
            "dirs": items.filter({ $0.isDir }),
            "files": items.filter({ !$0.isDir }),
        ]

        DispatchQueue.main.sync {
            context["title"] = customTitleTf.text ?? ""
        }

        return context
    }


    // MARK: UIDocumentPickerDelegate

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard controller.documentPickerMode == .import &&
            urls.count > 0
        else {
            return
        }

        let offset = items.count

        items += urls.map { File($0) }

        tableView.insertRows(at: urls.indices.map { IndexPath(row: offset + $0, section: 0) },
                             with: .automatic)

        startSharingBt.isEnabled = !items.isEmpty
    }
}
