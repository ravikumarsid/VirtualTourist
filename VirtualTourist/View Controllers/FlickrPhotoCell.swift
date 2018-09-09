//
//  MyCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Ravi Kumar Venuturupalli on 8/13/18.
//  Copyright © 2018 Ravi Kumar Venuturupalli. All rights reserved.
//

import UIKit
import SwiftGifOrigin

class FlickrPhotoCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.imageView.alpha = 0.30
                self.isHighlighted = true
            } else {
                self.imageView.alpha = 1.0
                self.isHighlighted = false
            }
        }
    }
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = contentView.center
        contentView.addSubview(activityIndicator)
        return activityIndicator
    }()
    
}

