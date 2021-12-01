//
//  FileManager+Utils.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 12.10.21.
//

import Foundation

public extension FileManager {

    var cacheDir: URL? {
        urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    var docsDir: URL? {
        urls(for: .documentDirectory, in: .userDomainMask).first
    }

    /**
     Store data in <appdir>/Library/Caches/tor (Library/Caches/ is for things that can persist between
     launches -- which we'd like so we keep descriptors & etc -- but don't need to be backed up because
     they can be regenerated by the app)
     */
    var torDir: URL? {
        guard let url = cacheDir?.appendingPathComponent("tor", isDirectory: true) else {
            return nil
        }

        // Create tor data directory if it does not yet exist.
        try? createSecureDirIfNotExists(at: url)

        return url
    }

    var serviceDir: URL? {
        torDir?.appendingPathComponent("web", isDirectory: true)
    }

    var pubKeyDir: URL? {
        guard let url = serviceDir?.appendingPathComponent("authorized_clients", isDirectory: true) else {
            return nil
        }

        // Try to create the public key directory, if it doesn't exist, yet.
        // Tor will do that on first start, but then we would need to restart
        // to make it load the key.
        // However, we need to be careful with access flags, because
        // otherwise Tor will complain and reject its use.
        try? createSecureDirIfNotExists(at: url)

        return url
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
