//
//  AlbumViewController.swift
//  MyAlbum
//
//  Created by kwon on 2021/08/19.
//

import UIKit
import Photos

class AlbumViewController: UIViewController, UICollectionViewDataSource, PHPhotoLibraryChangeObserver {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var albumTitle: String?
    var photos: PHFetchResult<PHAssetCollection>?
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    var isOrderedByCreationDate: Bool = false
    enum order: String {
        case latest = "최신순"
        case oldest = "과거순"
    }
    
    @IBAction func touchUpOrderBarItem(_ sender: UIBarItem) {
        guard let title = sender.title else {
            preconditionFailure("정렬 버튼 정보 조회 오류")
        }
        
        switch title {
        case order.latest.rawValue:
            sender.title = order.oldest.rawValue
            self.isOrderedByCreationDate = true
        default:
            sender.title = order.latest.rawValue
            self.isOrderedByCreationDate = false
        }
        
        OperationQueue.main.addOperation {
            self.collectionView.performBatchUpdates({
                let indexSet = IndexSet(integer: 0)
                self.collectionView.reloadSections(indexSet)
            }, completion: nil)
        }
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        //
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos?.firstObject?.photosCount ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell: ImageCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ImageCollectionViewCell else {
            preconditionFailure("콜렉션 뷰 셀 생성 오류")
        }
        
        guard let collection = self.photos?.firstObject else {
            preconditionFailure("앨범 불러오기 오류")
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: isOrderedByCreationDate)]
        
        let photo = PHAsset.fetchAssets(in: collection, options: fetchOptions).object(at: indexPath.row)
        let imageOption: PHImageRequestOptions = PHImageRequestOptions()
        imageOption.resizeMode = .exact
        
        let third: CGFloat = floor((UIScreen.main.bounds.width - 10) / 3.0)
        
        imageManager.requestImage(for: photo,
                                  targetSize: CGSize(width: third, height: third),
                                  contentMode: .aspectFill,
                                  options: imageOption,
                                  resultHandler: { image, _ in
                                    cell.imageView.image = image
        })
        
        return cell
    }
    
    func requestCollection() {
        guard let title = self.albumTitle else {
            preconditionFailure("선택한 앨범을 찾을 수 없음")
        }
        
        var photos: PHFetchResult<PHAssetCollection>? = nil
        
        if title == "Recents" {
            photos = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        } else if title == "Favorites" {
            photos = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil)
        } else {
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", title)
            
            photos = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        }
        
        self.photos = photos
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = self.albumTitle
        
        self.requestCollection()
        
        OperationQueue.main.addOperation {
            self.collectionView.reloadData()
        }
        
        let third: CGFloat = floor((UIScreen.main.bounds.width - 10) / 3.0)
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.minimumLineSpacing = 5
        flowLayout.itemSize = CGSize(width: third, height: third)
        
        self.collectionView.collectionViewLayout = flowLayout
        
        // 유저의 모든 Photo Assets을 불러오기 위해
        PHPhotoLibrary.shared().register(self)
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
