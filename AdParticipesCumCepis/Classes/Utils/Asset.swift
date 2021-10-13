//
//  Asset.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 13.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Photos
import TLPhotoPicker
import SwiftUTI

open class Asset {

    open var basename: String?

    open var size: Int64? {
        didSet {
            if let size = size {
                size_human = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
            else {
                size_human = nil
            }
        }
    }

    open var size_human: String?

    open var link: String?

    open var tlPhAsset: TLPHAsset?


    private lazy var thumbnailImageOptions: PHImageRequestOptions = {
        let o = PHImageRequestOptions()
        o.isNetworkAccessAllowed = false
        o.isSynchronous = false
        o.resizeMode = .fast
        o.version = .current

        return o
    }()

    private lazy var sizeImageOptions: PHImageRequestOptions = {
        let o = PHImageRequestOptions()
        o.deliveryMode = .fastFormat
        o.isNetworkAccessAllowed = false
        o.isSynchronous = false
        o.resizeMode = .none
        o.version = .current

        return o
    }()

    private lazy var sizeVideoOptions: PHVideoRequestOptions = {
        let o = PHVideoRequestOptions()
        o.deliveryMode = .fastFormat
        o.isNetworkAccessAllowed = false
        o.version = .current

        return o
    }()

    private lazy var originalImageOptions: PHImageRequestOptions = {
        let o = PHImageRequestOptions()
        o.isNetworkAccessAllowed = true
        o.isSynchronous = false
        o.resizeMode = .none
        o.version = .current

        return o
    }()

    private lazy var exportVideoOptions: PHVideoRequestOptions = {
        let o = PHVideoRequestOptions()
        o.deliveryMode = .automatic
        o.isNetworkAccessAllowed = true
        o.version = .current

        return o
    }()

    public init(_ asset: TLPHAsset) {
        tlPhAsset = asset
        basename = asset.originalFileName

        if let name = basename {
            link = "/assets/\(name)"
        }

        if asset.type == .video {
            asset.videoSize(options: sizeVideoOptions) { size in
                self.size = Int64(size)
            }
        }
        else {
            asset.photoSize(options: sizeImageOptions, completion: { size in
                self.size = Int64(size)
            }, livePhotoVideoSize: true)
        }
    }

    open func getThumbnail(_ resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        guard let phAsset = tlPhAsset?.phAsset else {
            resultHandler(nil, nil)

            return
        }

        PHCachingImageManager.default().requestImage(
            for: phAsset, targetSize: CGSize(width: 160, height: 160),
               contentMode: .aspectFit, options: thumbnailImageOptions,
               resultHandler: resultHandler)
    }

    open func getOriginal(_ resultHandler: @escaping (_ data: Data?, _ contentType: String?) -> Void) {
        guard let tlPhAsset = tlPhAsset,
              let phAsset = tlPhAsset.phAsset
        else {
            resultHandler(nil, nil)

            return
        }

        if tlPhAsset.type == .video {
//            PHCachingImageManager.default().requestPlayerItem(
//                forVideo: phAsset, options: exportVideoOptions)
//            { item, info in
//                item.
//            }
//
//            PHCachingImageManager.default().requestExportSession(
//                forVideo: phAsset,
//                options: exportVideoOptions,
//                exportPreset: AVAssetExportPresetMediumQuality)
//            { session, info in
//                session.
//            }

            resultHandler(nil, nil)
        }
        else {
            PHCachingImageManager.default().requestImageData(
                for: phAsset, options: originalImageOptions)
            { (imageData, dataUTI, orientation, info) in
                var uti = UTI.image

                if let dataUTI = dataUTI {
                    uti = UTI(rawValue: dataUTI)
                }

                resultHandler(imageData, uti.mimeType)
            }
        }
    }
}
