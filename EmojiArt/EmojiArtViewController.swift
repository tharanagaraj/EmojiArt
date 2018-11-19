//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Thara Nagaraj on 11/18/18.
//  Copyright © 2018 Thara Nagaraj. All rights reserved.
//

import UIKit

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate {

    @IBOutlet weak var dropZone: UIView!{
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    @IBOutlet weak var emojiArtView: EmojiArtView!
    
    
    //accept drops that have both URL and image
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    
    var imageFetcher : ImageFetcher!
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        imageFetcher = ImageFetcher(){(url, image) in
            DispatchQueue.main.async {
                self.emojiArtView.backgroundImage = image
            }
        }
        
        //nsurl is of type ItemProvider, so cast to URL
       session.loadObjects(ofClass: NSURL.self) {nsurls in
        if let url = nsurls.first as? URL{
            self.imageFetcher.fetch(url)
        }
       }
        //uiimage is of type ItemProvider, so cast to URL
        session.loadObjects(ofClass: UIImage.self) {images in
            if let image = images.first as? UIImage{
                 self.imageFetcher.backup = image
            }
        }
    }
}
