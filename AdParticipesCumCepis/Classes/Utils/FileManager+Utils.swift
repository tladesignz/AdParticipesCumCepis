//
//  FileManager+Utils.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 12.10.21.
//

import Foundation

public extension FileManager {

    var cacheDir: URL? {
        return urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    var docsDir: URL? {
        return urls(for: .documentDirectory, in: .userDomainMask).first
    }

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

    func size(of url: URL) -> Int64? {
        return (try? attributesOfItem(atPath: url.path))?[.size] as? Int64
    }

    func contentsOfDirectory(at url: URL?) -> [URL] {
        guard let url = url else {
            return []
        }

        return (try? contentsOfDirectory(
            at: url, includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles)) ?? []
    }
}
