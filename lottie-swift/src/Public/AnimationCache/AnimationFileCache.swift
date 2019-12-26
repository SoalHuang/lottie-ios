//
//  AnimationFileCache.swift
//  Lottie
//
//  Created by SoalHunag on 2019/12/26.
//  Copyright © 2019 YurtvilleProds. All rights reserved.
//

import Foundation
import CommonCrypto

extension String {
    
    var SHA1: String {
        let str = cString(using: String.Encoding.utf8) ?? []
        let strLen = CUnsignedInt(lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_SHA1(str, strLen, result)
        let hash = NSMutableString()
        for i in (0..<digestLen) {
            hash.appendFormat("%02x", result[i])
        }
        defer { result.deallocate() }
        return String(format: hash as String)
    }
}

extension AnimationFileCache {
    
    public func animation(for key: String) -> Animation? {
        let path = filePath(for: key)
        let url = URL(fileURLWithPath: path, isDirectory: false)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Animation.self, from: data)
    }
    
    public func setAnimation(_ animation: Animation, for key: String) {
        guard let data = try? JSONEncoder().encode(animation) else { return }
        let path = filePath(for: key)
        let url = URL(fileURLWithPath: path, isDirectory: false)
        do {
            try data.write(to: url)
        } catch {
            #if DEBUG
            print("write lottie data failed: \(error.localizedDescription)")
            #endif
        }
    }
    
    public func clearCache() {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: directoryPath) else { return }
        contents.forEach {
            try? FileManager.default.removeItem(atPath: directoryPath.appending("/\($0)"))
        }
    }
}

public class AnimationFileCache {
    
    static let shared = AnimationFileCache()
    
    private let directoryPath = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first ?? NSTemporaryDirectory()).appending("/LottieFileCache")
    
    init() {
        createDirectoryIfNotExist()
    }
    
    private func createDirectoryIfNotExist() {
        var isDirectory: ObjCBool = ObjCBool(false)
        let fileExist = FileManager.default.fileExists(atPath: directoryPath, isDirectory: &isDirectory)
        if fileExist, isDirectory.boolValue { return }
        do {
            try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            #if DEBUG
            print("create lottie animation cache directory failed: \(error.localizedDescription)")
            #endif
        }
    }
    
    private func filePath(for key: String) -> String {
        return directoryPath + "/" + key.SHA1
    }
}
