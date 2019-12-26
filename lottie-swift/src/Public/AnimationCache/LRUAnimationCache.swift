//
//  LRUAnimationCache.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 2/5/19.
//

import Foundation

extension LRUAnimationCache: AnimationCacheProvider {
    
    public func animation(for key: String) -> Animation? {
        let updateLru = {
            guard let index = self.lruList.firstIndex(of: key) else { return }
            self.lruList.remove(at: index)
            self.lruList.append(key)
        }
        if let animation = cacheMap[key] {
            updateLru()
            return animation
        }
        guard let animation = fileCache.animation(for: key) else {
            return nil
        }
        cacheMap[key] = animation
        updateLru()
        return animation
    }
    
    public func setAnimation(_ animation: Animation, for key: String, writeInDisk: Bool) {
        cacheMap[key] = animation
        lruList.append(key)
        if lruList.count > cacheSize {
            lruList.remove(at: 0)
        }
        if writeInDisk {
            fileCache.setAnimation(animation, for: key)
        }
    }
    
    public func clearCache() {
        clearMemoryCache()
        clearDiskCache()
    }
    
    public func clearMemoryCache() {
        cacheMap.removeAll()
        lruList.removeAll()
    }
    
    public func clearDiskCache() {
        fileCache.clearCache()
    }
}

/**
 An Animation Cache that will store animations up to `cacheSize`.
 
 Once `cacheSize` is reached, the least recently used animation will be ejected.
 The default size of the cache is 100.
 */
public class LRUAnimationCache {
    
    public init() { }
    
    /// The global shared Cache.
    public static let sharedCache = LRUAnimationCache()
    
    /// The size of the cache.
    public var cacheSize: Int = 100
    
    fileprivate var cacheMap: [String: Animation] = [:]
    fileprivate var lruList: [String] = []
    
    private let fileCache = AnimationFileCache.shared
}
