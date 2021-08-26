//
//  DetailViewController.swift
//  MyAlbum
//
//  Created by kwon on 2021/08/21.
//

import UIKit
import Photos

class DetailViewController: UIViewController, PHPhotoLibraryChangeObserver {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    var asset: PHAsset?
    var localIdentifier: String?

    @IBAction func touchUpFavoriteToolbarItem(_ sender: UIBarButtonItem) {
        // Before editing an asset, use its canPerform(_:) method to see if the asset allows editing.
        guard let isEditable = self.asset?.canPerform(PHAssetEditOperation.properties) else {
            return
        }
        
        guard let photo = self.asset else {
            return
        }
        
        if isEditable {
            PHPhotoLibrary.shared().performChanges({
                let assetChangeRequest = PHAssetChangeRequest.init(for: photo)
                assetChangeRequest.isFavorite = !(self.asset?.isFavorite ?? false)
            }, completionHandler: { isCompleted, _ in
                guard let localIdentifier = self.localIdentifier else {
                    return
                }
                
                guard let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject else {
                    return
                }
                
                self.asset = result
                
                OperationQueue.main.addOperation {
                    if result.isFavorite {
                        self.favoriteButton.title = "❤️"
                    } else {
                        self.favoriteButton.title = "🖤"
                    }
                }
            })
        }
    }
    
    // asset의 isFavorite을 바꿔주고 나서도 호출되지 않음... 결국 completeHandler에서 전부 처리했는데... 이상하게 또 다른 컨트롤러에서는 이 함수가 변화를 감지함;
    func photoLibraryDidChange(_ changeInstance: PHChange) {
//        guard let photo = self.asset, let changeDetails = changeInstance.changeDetails(for: photo) else {
//            return
//        }
//
//        self.asset = changeDetails.objectAfterChanges
    }
    
    @IBAction func touchUpShareToolbarItem(_ sender: UIBarButtonItem) {
        guard let photo =  self.imageView.image else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [photo], applicationActivities: nil)
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let asset = self.asset else {
            return
        }
        
        self.localIdentifier = asset.localIdentifier
        
        if let creationDate = self.asset?.creationDate {
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()
            
            let timeFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .none
                formatter.timeStyle = .medium
                formatter.dateFormat = "a hh:mm:ss"
                return formatter
            }()
            
            let titleLabel = UILabel.init(frame: CGRect.zero)
            titleLabel.backgroundColor = UIColor.clear
            titleLabel.textColor = UIColor.black
            titleLabel.font = UIFont.systemFont(ofSize: 15)
            titleLabel.textAlignment = .center
            titleLabel.text = dateFormatter.string(from: creationDate)
            titleLabel.sizeToFit()

            let subTitleLabel = UILabel.init(frame: CGRect.init(x: 0, y: titleLabel.intrinsicContentSize.height, width: 0, height: 0))
            subTitleLabel.backgroundColor = UIColor.clear
            subTitleLabel.textColor = UIColor.darkGray
            subTitleLabel.font = UIFont.systemFont(ofSize: 12)
            subTitleLabel.textAlignment = .center
            subTitleLabel.text = timeFormatter.string(from: creationDate)
            subTitleLabel.sizeToFit()
            
            let twoLineTitleView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: max(titleLabel.frame.size.width, subTitleLabel.frame.size.width) , height: (titleLabel.frame.height + subTitleLabel.frame.height)))
            
            if titleLabel.frame.width >= subTitleLabel.frame.width {
                var adjustment = subTitleLabel.frame
                adjustment.origin.x = twoLineTitleView.frame.origin.x + (twoLineTitleView.frame.width/2) - (subTitleLabel.frame.width/2)
                subTitleLabel.frame = adjustment
            } else {
                var adjustment = titleLabel.frame
                adjustment.origin.x = twoLineTitleView.frame.origin.x + (twoLineTitleView.frame.width/2) - (titleLabel.frame.width/2)
                titleLabel.frame = adjustment
            }
            
            twoLineTitleView.addSubview(titleLabel)
            twoLineTitleView.addSubview(subTitleLabel)
            
            self.navigationItem.titleView = twoLineTitleView
        }
        
        let imageManager: PHCachingImageManager = PHCachingImageManager()
        imageManager.requestImage(for: asset,
                                  targetSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height),
                                  contentMode: .aspectFill,
                                  options: nil,
                                  resultHandler: { image, _ in
                                    self.imageView.image = image
                                    if asset.isFavorite {
                                        self.favoriteButton.title = "❤️"
                                    } else {
                                        self.favoriteButton.title = "🖤"
                                    }
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
