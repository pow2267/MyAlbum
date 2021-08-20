//
//  ImageCollectionViewCell.swift
//  MyAlbum
//
//  Created by kwon on 2021/08/19.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.layer.borderWidth = 2
                self.layer.backgroundColor = UIColor.white.cgColor
            } else {
                self.layer.borderWidth = 0
                self.layer.backgroundColor = nil
            }
        }
    }
}
