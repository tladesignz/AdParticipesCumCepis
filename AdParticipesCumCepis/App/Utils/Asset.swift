//
//  Asset.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 13.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Photos
import TLPhotoPicker
import UniformTypeIdentifiers

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

    private lazy var tempFile: URL? = {
        guard let filename = basename,
              let dir = fm.cacheDir?.appendingPathComponent("assets", isDirectory: true)
        else {
            return nil
        }

        // Store in subfolder, otherwise collisions might happen.
        if !fm.fileExists(at: dir) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return dir.appendingPathComponent(filename)
            .deletingPathExtension()
            // Set correct extension, so GCDWebServer can figure out correct MIME type
            .appendingPathExtension("mp4")
    }()


    public init(_ asset: TLPHAsset) {
        tlPhAsset = asset

        super.init(name: asset.originalFileName)

        if asset.type == .video {
            if let tempFile = tempFile, fm.fileExists(at: tempFile) {
                size = fm.size(of: tempFile)
            }

            if size == nil {
                asset.videoSize(options: sizeVideoOptions) { [weak self] size in
                    self?.size = Int64(size)
                }
            }
        }
        else {
            asset.photoSize(options: sizeImageOptions, completion: { [weak self] size in
                self?.size = Int64(size)
            }, livePhotoVideoSize: true)
        }
    }

    open override func getThumbnail(_ resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        guard let phAsset = tlPhAsset?.phAsset else {
            resultHandler(nil, nil)

            return
        }

        phManager.requestImage(
            for: phAsset, targetSize: CGSize(width: Item.thumbnailSize, height: Item.thumbnailSize),
               contentMode: .aspectFit, options: thumbnailImageOptions,
               resultHandler: resultHandler)
    }

    open override func original(_ resultHandler: @escaping (_ file: URL?, _ data: Data?, _ contentType: String?) -> Void) {
        guard let tlPhAsset = tlPhAsset,
              let phAsset = tlPhAsset.phAsset
        else {
            return resultHandler(nil, nil, nil)
        }

        if tlPhAsset.type == .video {
            guard let tempFile = tempFile else {
                return resultHandler(nil, nil, nil)
            }

            if fm.fileExists(at: tempFile) {
                return resultHandler(tempFile, nil, nil)
            }

            phManager.requestAVAsset(forVideo: phAsset, options: exportVideoOptions) {
                [weak self] avAsset, audioMix, info in

                guard let avAsset = avAsset else {
                    return resultHandler(nil, nil, nil)
                }

                let presets = AVAssetExportSession.exportPresets(compatibleWith: avAsset)
                var preset: String? = presets.first // The first one should be a rather low quality.

                // Try to use the medium quality, which should be good enough for now.
                if presets.contains(AVAssetExportPresetMediumQuality) {
                    preset = AVAssetExportPresetMediumQuality
                }

                guard let preset = preset else {
                    return resultHandler(nil, nil, nil)
                }

                self?.phManager.requestExportSession(forVideo: phAsset, options: self?.exportVideoOptions, exportPreset: preset) {
                    exportSession, info in

                    guard let exportSession = exportSession else {
                        return resultHandler(nil, nil, nil)
                    }

                    exportSession.outputURL = tempFile
                    exportSession.outputFileType = .mp4

                    exportSession.exportAsynchronously {
                        switch exportSession.status {
                        case .completed:
                            // Update with correct size of export.
                            self?.size = self?.fm.size(of: tempFile)

                            return resultHandler(tempFile, nil, nil)

                        case .failed, .cancelled:
                            try? self?.fm.removeItem(at: tempFile)

                            return resultHandler(nil, nil, nil)

                        default:
                            break
                        }
                    }
                }
            }
        }
        else {
            phManager.requestImageDataAndOrientation(
                for: phAsset, options: originalImageOptions)
            { imageData, dataUTI, orientation, info in
                var uti: UTType?

                if let dataUTI = dataUTI {
                    uti = UTType(dataUTI)
                }

                resultHandler(nil, imageData, (uti ?? UTType.image).preferredMIMEType)
            }
        }
    }

    open override func remove() throws {
        // Only remove temp file used in video export, if it exists.
        if let tempFile = tempFile, fm.fileExists(at: tempFile) {
            try fm.removeItem(at: tempFile)
        }
    }
}
