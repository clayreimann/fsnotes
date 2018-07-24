//
//  ImageAttachment.swift
//  FSNotes
//
//  Created by Oleksandr Glushchenko on 7/15/18.
//  Copyright © 2018 Oleksandr Glushchenko. All rights reserved.
//

import Foundation

#if os(OSX)
    import Cocoa
#else
    import UIKit
#endif

class ImageAttachment {
    private var title: String
    private var path: String
    private var url: URL
    private var cache: URL?
    
    init(title: String, path: String, url: URL, cache: URL?) {
        self.title = title
        self.url = url
        self.path = path
        self.cache = cache
    }
    
    public func getAttributedString() -> NSMutableAttributedString?  {
        let pathKey = NSAttributedStringKey(rawValue: "co.fluder.fsnotes.image.path")
        let titleKey = NSAttributedStringKey(rawValue: "co.fluder.fsnotes.image.title")
        
        let attachment = NSTextAttachment()
        var saveCache: URL?
        
        if self.url.isRemote(),
            let cacheName = self.url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
            let imageCacheUrl = self.cache?.appendingPathComponent(cacheName) {
            
            if FileManager.default.fileExists(atPath: imageCacheUrl.path) {
                self.url = imageCacheUrl
            } else {
                saveCache = imageCacheUrl
            }
        }
        
        guard let imageData = try? Data(contentsOf: self.url),
            let image = Image(data: imageData) else {
            return nil
        }
        
        if let imageCacheUrl = saveCache {
            try? FileManager.default.createDirectory(at: imageCacheUrl.deletingLastPathComponent(), withIntermediateDirectories: false, attributes: nil)
            try? imageData.write(to: imageCacheUrl, options: .atomic)
        }
        
        #if os(OSX)
            let fileWrapper = FileWrapper.init()
            fileWrapper.icon = image
            attachment.fileWrapper = fileWrapper
        #else
            attachment.image = resizeImage(image: image)
        #endif
        
        let attributedString = NSAttributedString(attachment: attachment)
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        
        let ps = NSMutableParagraphStyle()
        ps.alignment = .center
        ps.lineSpacing = CGFloat(UserDefaultsManagement.editorLineSpacing)
        
        let attributes = [
                titleKey: self.title,
                pathKey: self.path,
                .link: String(),
                .attachment: attachment,
                .paragraphStyle: ps
            ] as [NSAttributedStringKey : Any]
        
        mutableString.addAttributes(attributes, range: NSRange(0..<1))
        
        return mutableString
    }
    
    #if os(iOS)
        private func resizeImage(image: UIImage) -> UIImage? {
            guard
                let pageController = UIApplication.shared.windows[0].rootViewController as? PageViewController,
                let viewController = pageController.orderedViewControllers[1] as? UINavigationController,
                let evc = viewController.viewControllers[0] as? EditorViewController else {
                    return nil
            }
            
            let maxWidth = evc.view.frame.width
            
            guard image.size.width > maxWidth else {
                return image
            }
            
            let scale = maxWidth / image.size.width
            let newHeight = image.size.height * scale
            UIGraphicsBeginImageContext(CGSize(width: maxWidth, height: newHeight))
            image.draw(in: CGRect(x: 0, y: 0, width: maxWidth, height: newHeight))
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage
        }
    #endif

}
