//
//  PhotoHandler.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import Foundation
import Photos
import UIKit
import ImageIO

actor PhotoHandler {
    
    let thumbnails: AsyncStream<CGImage?>
    private let continuation: AsyncStream<CGImage?>.Continuation?
    
    init() {
        let (thumbnails, continuation) = AsyncStream.makeStream(of: CGImage?.self)
        self.thumbnails = thumbnails
        self.continuation = continuation
    }

    func save(photo: Photo, to session: inout SessionData, in item: inout ItemData) async throws {
        print("Saving photo to session: \(session.id), item: \(item.id)")
        let thumbnail = await generateThumbnail(from: photo)
        if let thumbnail = thumbnail {
                print("Generated and yielded thumbnail: \(thumbnail)")
            } else {
                print("Failed to generate thumbnail")
            }
        item.images.append(UIImage(data: photo.data)!)
        continuation?.yield(thumbnail)
        print("Generated and yielded thumbnail: \(String(describing: thumbnail))")
    }
    
    private func generateThumbnail(from photo: Photo) async -> CGImage? {
        // Load image data
        guard let source = CGImageSourceCreateWithData(photo.data as CFData, nil) else {
            return nil
        }
        
        // Extract orientation metadata
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let orientationValue = properties?[kCGImagePropertyOrientation] as? UInt32 ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: orientationValue) ?? .up
        
        // Generate thumbnail
        let options = [kCGImageSourceThumbnailMaxPixelSize as String: 256,
                       kCGImageSourceCreateThumbnailFromImageAlways as String: true] as CFDictionary
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            return nil
        }
        
        // Apply orientation
        return thumbnail.oriented(orientation)
    }
}

private extension CGImage {
    func oriented(_ orientation: CGImagePropertyOrientation) -> CGImage {
        let ciImage = CIImage(cgImage: self).oriented(orientation)
        let context = CIContext(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent) ?? self
    }
}
