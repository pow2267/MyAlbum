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
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
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
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", title)
        
        let photos: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        self.photos = photos
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = self.albumTitle
        
        self.requestCollection()
        
        OperationQueue.main.addOperation {
            self.collectionView.reloadData()
        }
        
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.minimumLineSpacing = 5
        
        let third: CGFloat = floor((UIScreen.main.bounds.width - 10) / 3.0)
        
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
