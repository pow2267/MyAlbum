//
//  ViewController.swift
//  MyAlbum
//
//  Created by kwon on 2021/08/16.
//

import UIKit
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var recents: PHFetchResult<PHAssetCollection>?
    var favorites: PHFetchResult<PHAssetCollection>?
    var albums: PHFetchResult<PHAssetCollection>?
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    
    // 포토 앨범 조회
    func requestCollection() {
        // Recents, Favorites는 사용자 정의 앨범이 아닌 스마트 앨범이라 따로 조회
        self.recents = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        self.favorites = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil)
        self.albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let photoAuthorization = PHPhotoLibrary.authorizationStatus()
        
        // 포토 라이브러리 권한 체크
        switch photoAuthorization {
        case .authorized, .limited:
            self.requestCollection()
            OperationQueue.main.addOperation {
                self.collectionView.reloadData()
            }
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (state) in
                switch state {
                case .authorized, .limited:
                    self.requestCollection()
                    OperationQueue.main.addOperation {
                        self.collectionView.reloadData()
                    }
                    
                default:
                    break
                }
            })
            
        default:
            break
        }
        
        // 콜렉션 뷰 레이아웃 설정
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        flowLayout.minimumInteritemSpacing = 10
        flowLayout.minimumLineSpacing = 10
        
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        var length: CGFloat = (width - 50) / 2.0
        
        // 가로 모드일 때
        if width > height {
            length = (height - 50) / 2.0
        }
        
        // +40은 밑에 앨범 이름과 사진 개수 label용
        flowLayout.itemSize = CGSize(width: length, height: length + 40)
        
        self.collectionView.collectionViewLayout = flowLayout
        
        // 유저의 모든 Photo Assets을 불러오기 위해
        PHPhotoLibrary.shared().register(self)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let albumViewController: AlbumViewController = segue.destination as? AlbumViewController else {
            return
        }
        
        guard let cell: PhotoListCollectionViewCell = sender as? PhotoListCollectionViewCell else {
            return
        }
        
        albumViewController.albumTitle = cell.titleLabel.text
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell: PhotoListCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? PhotoListCollectionViewCell else {
            preconditionFailure("콜렉션 뷰 셀 생성 오류")
        }
        
        /* Q. 앱이 가장 처음 로드될 때 몇몇 앨범의 이미지가 빠르게 바뀌곤 하는데, 비동기로 앨범의 썸네일을 불러와서 이런 현상이 생기는 걸까요?
            만약 비동기가 원인이 맞다면, 깜빡이는 현상을 방지하기 위해서 어떻게 해야할까요? */
        OperationQueue().addOperation {
            let collections: PHAssetCollection?
            
            switch indexPath.row {
            case 0:
                collections = self.recents?.firstObject
            case 1:
                collections = self.favorites?.firstObject
            default:
                collections = self.albums?.object(at: indexPath.row - 2) // 0, 1번이 각각 Recents, Favorites이라서 index에서 2를 빼줌
            }
            
            if collections != nil {
                if let asset = PHAsset.fetchAssets(in: collections!, options: nil).lastObject {
                    OperationQueue.main.addOperation {
                        cell.titleLabel.text = collections!.localizedTitle
                        cell.countLabel.text = String(collections!.photosCount)
                        
                        let imageOption: PHImageRequestOptions = PHImageRequestOptions()
                        imageOption.resizeMode = .exact
                        imageOption.isSynchronous = true
                        
                        self.imageManager.requestImage(for: asset,
                                                  targetSize: CGSize(width: cell.frame.width, height: cell.frame.height),
                                                  contentMode: .aspectFill,
                                                  options: imageOption,
                                                  resultHandler: { image, _ in
                                                        cell.imageView.image = image
                        })
                    }
                } else {
                    cell.imageView.image = nil
                }
            } else {
                cell.imageView.image = nil
            }
        }
        
        // 이미지 뷰의 가장자리 둥글게
        cell.imageView.layer.cornerRadius = cell.imageView.frame.width / 40
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.albums?.count ?? 0) + 2 // Recents, Favorites 폴더 2개 포함
    }
}

extension ViewController: PHPhotoLibraryChangeObserver {
    // 포토 라이브러리에 변화를 감지하면 view reload
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        OperationQueue.main.addOperation {
            self.viewDidLoad()
        }
    }
}

// AssetCollection에 속한 asset의 개수를 구하기 위해
// Q. 아래 코드는 ViewController 클래스가 아닌데 어느 파일에 위치해야 하나요?
extension PHAssetCollection {
    var photosCount: Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let result = PHAsset.fetchAssets(in: self, options: fetchOptions)
        
        return result.count
    }
}
