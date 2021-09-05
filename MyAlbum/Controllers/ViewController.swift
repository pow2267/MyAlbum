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
        
        /* review: 다음 ViewController에서 모든 PHAssetCollection을 다시 fetch하여 title을 이용하여 필터링하도록 구현해주셨네요.
         이미 다음 화면으로 넘어가는 시점에 어떤 PHAssetCollection을 사용해야 할 지 알고 있으므로 collection을 넘겨주는 것이 어떨까요?
         fetch하는 행위는 무거운 동작이므로 가급적이면 최소화하는 것이 좋습니다. */
        guard let cell: PhotoListCollectionViewCell = sender as? PhotoListCollectionViewCell,
              let index = collectionView.indexPath(for: cell)?.item else {
            return
        }

        let collection: PHAssetCollection?

        switch index {
        case 0:
            collection = self.recents?.firstObject
        case 1:
            collection = self.favorites?.firstObject
        default:
            collection = self.albums?.object(at: index - 2) // 0, 1번이 각각 Recents, Favorites이라서 index에서 2를 빼줌
        }

        albumViewController.assetCollection = collection
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell: PhotoListCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? PhotoListCollectionViewCell else {
            preconditionFailure("콜렉션 뷰 셀 생성 오류")
        }
        
        /* Q. 앱이 가장 처음 로드될 때 몇몇 앨범의 이미지가 빠르게 바뀌곤 하는데, 비동기로 앨범의 썸네일을 불러와서 이런 현상이 생기는 걸까요?
            만약 비동기가 원인이 맞다면, 깜빡이는 현상을 방지하기 위해서 어떻게 해야할까요? */
        /* 1. fetchAssets 행위 두 번 일어나고 있습니다. (섬네일 애셋 + 이미지 갯수 추출)
         2. background thread에서 UI에 접근하여 크래시가 발생합니다.
         3. 섬네일 추출 시 미디어 타입에 대한 predicate이 없어 비디오에 대한 섬네일이 추출될 수 있습니다.
         4. 강제 언래핑보다는 옵셔널 언래핑을 사용해주세요. */
        OperationQueue().addOperation {
            let collection: PHAssetCollection?
            
            switch indexPath.row {
            case 0:
                collection = self.recents?.firstObject
            case 1:
                collection = self.favorites?.firstObject
            default:
                collection = self.albums?.object(at: indexPath.row - 2) // 0, 1번이 각각 Recents, Favorites이라서 index에서 2를 빼줌
            }
            
            if let collection = collection {
                
                let option = PHFetchOptions()                           // only image
                option.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                
                let result = PHAsset.fetchAssets(in: collection, options: option)
                
                DispatchQueue.main.async {
                    cell.titleLabel.text = collection.localizedTitle
                    cell.countLabel.text = "\(result.count)"
                }
                
                if let asset = result.lastObject {
                    OperationQueue.main.addOperation {
                        
                        let imageOption: PHImageRequestOptions = PHImageRequestOptions()
                        imageOption.resizeMode = .exact
                        imageOption.isSynchronous = true
                        
                        self.imageManager.requestImage(for: asset,
                                                  targetSize: CGSize(width: cell.frame.width, height: cell.frame.height),
                                                  contentMode: .aspectFill,
                                                  options: imageOption,
                                                  resultHandler: { image, _ in
                                                    DispatchQueue.main.async {
                                                            cell.imageView.image = image
                                                    }
                        })
                    }
                } else {
                    DispatchQueue.main.async {
                        cell.imageView.image = nil
                    }
                }
            } else {
                DispatchQueue.main.async {
                    cell.imageView.image = nil
                }
            }
        }
        
        // 이미지 뷰의 가장자리 둥글게
        DispatchQueue.main.async {
            cell.imageView.layer.cornerRadius = cell.imageView.frame.width / 40
        }
        
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
            /* review: viewDidLoad()는 시스템이 호출하는 함수로서, 직접 호출하는 것은 바람직하지 않습니다.
             (내부에서 super를 호출하기도 합니다.) */
            self.collectionView.reloadData()
        }
    }
}

// AssetCollection에 속한 asset의 개수를 구하기 위해
/* Q. 아래 코드는 ViewController 클래스가 아닌데 어느 파일에 위치해야 하나요?
review: A. 해당 extension이 사용되는 ViewController 파일에 위치시키거나 또는 관련 extension을 모아서 새로 파일을 생성하여 관리해도 됩니다. */
extension PHAssetCollection {
    var photosCount: Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let result = PHAsset.fetchAssets(in: self, options: fetchOptions)
        
        return result.count
    }
}
