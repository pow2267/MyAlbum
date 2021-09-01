//
//  DetailViewController.swift
//  MyAlbum
//
//  Created by kwon on 2021/08/21.
//

import UIKit
import Photos

class DetailViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var asset: PHAsset?
    var localIdentifier: String?
    
    @IBAction func touchUpTrashToolbarItem(_ sender: UIBarButtonItem) {
        guard let photo = self.asset else {
            return
        }
        
        let assets : NSMutableArray = NSMutableArray()
        assets.add(photo)
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets)
        }, completionHandler: { isDeleted, _ in
            if isDeleted {
                OperationQueue.main.addOperation {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        })
    }
    
    @IBAction func touchUpFavoriteToolbarItem(_ sender: UIBarButtonItem) {
        // asset을 수정하기 전에, canPerForm(_:) 메소드를 사용해 해당 asset이 수정 가능한지 아닌지 확인해야 함
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
                if isCompleted, let localIdentifier = self.localIdentifier, let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject {
                    self.asset = result
                    
                    /* Q. asset의 isFavorite값을 바꿔주고 나서도 이 뷰 컨트롤러에서 photoLibraryDidChange가 호출되지 않습니다
                    결국 completeHandler에서 전부 처리했는데, 이 뷰가 아닌 다른 뷰 컨트롤러에서는 photoLibraryDidChange 함수가 변화를 감지합니다. 이유가 뭔가요? */
                    OperationQueue.main.addOperation {
                        if result.isFavorite {
                            self.favoriteButton.title = "❤️"
                        } else {
                            self.favoriteButton.title = "🖤"
                        }
                    }
                }
            })
        }
    }
    
    @IBAction func touchUpShareToolbarItem(_ sender: UIBarButtonItem) {
        guard let photo =  self.imageView.image else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [photo], applicationActivities: nil)
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    /* touchedBegan은 scroll view에서는 동작하지 않음(scroll에서 single touch를 막음)
    그래서 gestureRecognizer를 따로 추가함*/
    @objc func showHideBars() {
        if self.view.backgroundColor == UIColor.black {
            self.navigationController?.navigationBar.isHidden = false
            self.toolbar.isHidden = false
            self.view.backgroundColor = UIColor.white
        } else {
            self.navigationController?.navigationBar.isHidden = true
            self.toolbar.isHidden = true
            self.view.backgroundColor = UIColor.black
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGuestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showHideBars))
        self.scrollView.addGestureRecognizer(tapGuestureRecognizer)

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
            
            // 두 줄짜리 타이틀 만들기
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
            
            // 타이틀 가운데 정렬
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
        
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 5.0
        scrollView.delegate = self
    }
}

extension DetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.navigationController?.navigationBar.isHidden = true
        self.toolbar.isHidden = true
        self.view.backgroundColor = UIColor.black
        
        // 코드 참고: https://www.youtube.com/watch?v=tBsUJzV1hmc
        if scrollView.zoomScale > 1 {
            if let image = self.imageView.image {
                let widthRatio = self.imageView.frame.width / image.size.width
                let heightRatio = self.imageView.frame.height / image.size.height
                
                let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
                
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                
                // boolean
                let conditionLeft = newWidth * scrollView.zoomScale > self.imageView.frame.width
                
                let left = (conditionLeft ? newWidth - self.imageView.frame.width : scrollView.frame.width - scrollView.contentSize.width) * 0.5
                
                // boolean
                let conditionTop = newHeight * scrollView.zoomScale > self.imageView.frame.height
                
                let top = (conditionTop ? newHeight - self.imageView.frame.height : scrollView.frame.height - scrollView.contentSize.height) * 0.5
                
                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
            }
        } else {
            scrollView.contentInset = UIEdgeInsets.zero
        }
    }
}
