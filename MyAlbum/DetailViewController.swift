//
//  DetailViewController.swift
//  MyAlbum
//
//  Created by kwon on 2021/08/21.
//

import UIKit
import Photos

class DetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var asset: PHAsset?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let asset = self.asset else {
            return
        }
        
        let imageManager: PHCachingImageManager = PHCachingImageManager()
        
        imageManager.requestImage(for: asset,
                                  targetSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height),
                                  contentMode: .aspectFill,
                                  options: nil,
                                  resultHandler: { image, _ in
                                    self.imageView.image = image
        })
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
