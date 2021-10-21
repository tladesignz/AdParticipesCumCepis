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

open class Asset: Item {

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

    private lazy var phManager = PHCachingImageManager.default()

    public init(_ asset: TLPHAsset) {
        tlPhAsset = asset

        super.init(name: asset.originalFileName)

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

    open override func getThumbnail(_ resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        guard let phAsset = tlPhAsset?.phAsset else {
            resultHandler(nil, nil)

            return
        }

        phManager.requestImage(
            for: phAsset, targetSize: CGSize(width: 160, height: 160),
               contentMode: .aspectFit, options: thumbnailImageOptions,
               resultHandler: resultHandler)
    }

    open override func getOriginal(_ resultHandler: @escaping (_ file: URL?, _ data: Data?, _ contentType: String?) -> Void) {
        guard let tlPhAsset = tlPhAsset,
              let phAsset = tlPhAsset.phAsset
        else {
            return resultHandler(nil, nil, nil)
        }

        if tlPhAsset.type == .video {
            let fm = FileManager.default

            guard let filename = basename,
                  var tempFile = fm.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(filename)
            else {
                return resultHandler(nil, nil, nil)
            }

            tempFile.deletePathExtension()
            tempFile.appendPathExtension("mp4")

            if fm.fileExists(atPath: tempFile.path) {
                return resultHandler(tempFile, nil, nil)
            }

            phManager.requestAVAsset(forVideo: phAsset, options: exportVideoOptions) {
                avAsset, audioMix, info in

                guard let avAsset = avAsset else {
                    return resultHandler(nil, nil, nil)
                }

                let presets = AVAssetExportSession.exportPresets(compatibleWith: avAsset)
                var preset: String? = presets.first

                // Try to use the medium quality, which should be good enough for now.
                if presets.contains(AVAssetExportPresetMediumQuality) {
                    preset = AVAssetExportPresetMediumQuality
                }

                guard let preset = preset else {
                    return resultHandler(nil, nil, nil)
                }

                self.phManager.requestExportSession(forVideo: phAsset, options: self.exportVideoOptions, exportPreset: preset) {
                    exportSession, info in

                    guard let exportSession = exportSession else {
                        return resultHandler(nil, nil, nil)
                    }

                    exportSession.outputURL = tempFile
                    exportSession.outputFileType = .mp4

                    exportSession.exportAsynchronously {
                        switch exportSession.status {
                        case .completed:
                            return resultHandler(tempFile, nil, nil)

                        case .failed, .cancelled:
                            try? fm.removeItem(at: tempFile)

                            return resultHandler(nil, nil, nil)

                        default:
                            break
                        }
                    }

                }
            }
        }
        else {
            phManager.requestImageData(
                for: phAsset, options: originalImageOptions)
            { (imageData, dataUTI, orientation, info) in
                var uti = UTI.image

                if let dataUTI = dataUTI {
                    uti = UTI(rawValue: dataUTI)
                }

                resultHandler(nil, imageData, uti.mimeType)
            }
        }
    }
}
