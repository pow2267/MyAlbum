//
//  ViewController.swift
//  MyAlbum
//
//  Created by kwon on 2021/08/16.
//

import UIKit
import Photos

class ViewController: UIViewController, UICollectionViewDataSource, PHPhotoLibraryChangeObserver {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var recents: PHFetchResult<PHAssetCollection>?
    var favorites: PHFetchResult<PHAssetCollection>?
    var albums: PHFetchResult<PHAssetCollection>?
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    
    func requestCollection() {
        let recents: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        
        let favorites: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil)
        
        let albums: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        
        self.recents = recents
        self.favorites = favorites
        self.albums = albums
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: self.albums!) else {
            return
        }
        
        albums = changes.fetchResultAfterChanges
        
        OperationQueue.main.addOperation {
            //
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell: PhotoListCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? PhotoListCollectionViewCell else {
            preconditionFailure("콜렉션 뷰 셀 생성 오류")
        }
        
        let imageOption: PHImageRequestOptions = PHImageRequestOptions()
        imageOption.resizeMode = .exact
        
        let collections: PHAssetCollection
        
        switch indexPath.row {
        case 0:
            guard let recents = self.recents?.firstObject else {
                preconditionFailure("최근 항목 불러오기 오류")
            }
            collections = recents
        case 1:
            guard let favorites = self.favorites?.firstObject else {
                preconditionFailure("즐겨찾는 항목 불러오기 오류")
            }
            collections = favorites
        default:
            guard let albums = self.albums?.object(at: indexPath.row - 2) else {
                preconditionFailure("\(indexPath.row - 2)번째 앨범 불러오기 오류")
            }
            collections = albums
        }
        
        if let asset = PHAsset.fetchAssets(in: collections, options: nil).lastObject {
            let half: CGFloat = (UIScreen.main.bounds.width - 50) / 2.0

            imageManager.requestImage(for: asset,
                                      targetSize: CGSize(width: half, height: half),
                                      contentMode: .aspectFill,
                                      options: imageOption,
                                      resultHandler: { image, _ in
                                            cell.imageView.image = image
            })
        } else {
            cell.imageView.image = nil
        }
        
        cell.titleLabel.text = collections.localizedTitle
        cell.countLabel.text = String(collections.photosCount)
        // 이미지 뷰의 가장자리 둥글게
        cell.imageView.layer.cornerRadius = cell.imageView.frame.width / 40
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.albums?.count ?? 0) + 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let photoAuthorization = PHPhotoLibrary.authorizationStatus()
        
        switch photoAuthorization {
        case .authorized:
            print("접근 허가 됨")
            self.requestCollection()
            OperationQueue.main.addOperation {
                self.collectionView.reloadData()
            }
            
        case .limited:
            print("제한 접근 허가")
            self.requestCollection()
            OperationQueue.main.addOperation {
                self.collectionView.reloadData()
            }
            
        case .denied:
            print("접근 불허")
            
        case .notDetermined:
            print("아직 응답하지 않음")
            PHPhotoLibrary.requestAuthorization({ (state) in
                switch state {
                case .authorized:
                    print("사용자가 허가 함")
                    self.requestCollection()
                    OperationQueue.main.addOperation {
                        self.collectionView.reloadData()
                    }
                    
                case .limited:
                    print("제한 접근 허가")
                    self.requestCollection()
                    OperationQueue.main.addOperation {
                        self.collectionView.reloadData()
                    }
                    
                case .denied:
                    print("사용자가 불허 함")
                    
                default:
                    break
                }
            })
            
        case .restricted:
            print("접근 제한")
            
        default:
            break
        }
        
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        flowLayout.minimumInteritemSpacing = 10
        flowLayout.minimumLineSpacing = 10
        
        let half: CGFloat = (UIScreen.main.bounds.width - 50) / 2.0
        
        flowLayout.itemSize = CGSize(width: half, height: half + 40)
        
        self.collectionView.collectionViewLayout = flowLayout
        
        // 유저의 모든 Photo Assets을 불러오기 위해
        PHPhotoLibrary.shared().register(self)
    }
}

// 어느 파일에 있어야 하나?
extension PHAssetCollection {
    var photosCount: Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let result = PHAsset.fetchAssets(in: self, options: fetchOptions)
        
        return result.count
    }
}
