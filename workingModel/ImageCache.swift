//
//  ImageCache.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 04/04/25.
//


import UIKit

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func image(for url: URL, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = cache.object(forKey: url.absoluteString as NSString) {
            completion(cachedImage)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data), error == nil else {
                completion(nil)
                return
            }

            self.cache.setObject(image, forKey: url.absoluteString as NSString)
            completion(image)
        }
        task.resume()
    }
}