//
//  FileManager+Utils.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 12.10.21.
//

import Foundation

extension FileManager {

    func createSecureDirIfNotExists(at url: URL) throws {
        // Try to remove it, if it is *not* a directory.
        if fileExists(atPath: url.path) {
            if !((try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false) {
                try removeItem(at: url)
            }
        }

        // Try to create it, and all its intermediate directories, if it doesn't
        // exist. Create with secure permissions.
        if !fileExists(atPath: url.path) {
            try createDirectory(
                at: url, withIntermediateDirectories: true,
                attributes: [.posixPermissions: NSNumber(value: 0o700)])
        }
    }
}
