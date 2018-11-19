//
//  EmojiArtView.swift
//  EmojiArt
//
//  Created by Thara Nagaraj on 11/18/18.
//  Copyright © 2018 Thara Nagaraj. All rights reserved.
//

import UIKit

class EmojiArtView: UIView {

    var backgroundImage : UIImage? {
        didSet{
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        backgroundImage?.draw(in: bounds)
    }
    

}
