//
//  ShowQrViewController.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 07.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

open class ShowQrViewController: UIViewController {

    @IBOutlet weak var qrCodeIv: UIImageView!
    @IBOutlet weak var qrCodeTv: UITextView!
    
    public var qrCode = ""
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("QR Code", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(done))

        qrCodeTv.text = qrCode
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        qrCodeIv.image = UIImage.qrCode(qrCode, qrCodeIv.bounds.size)
    }


    // MARK: Actions

    @objc func done() {
        if let navC = navigationController {
            navC.dismiss(animated: true)
        }
        else {
            dismiss(animated: true)
        }
    }
}
