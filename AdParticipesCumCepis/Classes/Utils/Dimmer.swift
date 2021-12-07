//
//  Dimmer.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 07.12.21.
//

import UIKit

open class Dimmer {

    public static let timeout: TimeInterval = 30

    public static let shared = Dimmer()


    private lazy var tapRec = UITapGestureRecognizer(target: self, action: #selector(reset))

    private var oldBrightness: CGFloat?

    private var timer: Timer?

    private weak var view: UIView?


    open func start() {
        reset()

        UIDevice.current.isProximityMonitoringEnabled = true

        if let rootVc = UIApplication.shared.delegate?.window??.rootViewController {
            view = (rootVc as? UINavigationController)?.topViewController?.view ?? rootVc.view
        }

        view?.addGestureRecognizer(tapRec)
        view?.isUserInteractionEnabled = true
    }

    open func stop(animated: Bool = true) {
        view?.removeGestureRecognizer(tapRec)
        view = nil

        reset(animated: animated)

        timer?.invalidate()

        UIDevice.current.isProximityMonitoringEnabled = false
    }

    @objc
    open func dimm() {
        if oldBrightness == nil {
            oldBrightness = UIScreen.main.brightness

            UIScreen.main.setBrightness(0, animated: true)
        }
    }

    @objc
    open func reset(animated: Bool = true) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: Self.timeout, target: self, selector: #selector(dimm),
            userInfo: nil, repeats: false)

        if let oldBrightness = oldBrightness {
            UIScreen.main.setBrightness(oldBrightness, animated: animated)
            self.oldBrightness = nil
        }
    }
}
