//
//  AlbumViewController.swift
//  MyAlbum
//
//  Created by kwon on 2021/08/19.
//

import UIKit
import Photos

class AlbumViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var orderItem: UIBarItem!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var albumTitle: String?
    var photos: PHFetchResult<PHAssetCollection>?
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    var isOrderedByCreationDate: Bool = false
    var isSelectMode: Bool = false
    var selectedCells: [IndexPath] = []
    
    @IBAction func touchUpTrashToolbarItem(_ sender: UIBarButtonItem) {
        // NSMutableArray: 동적으로 크기를 변경할 수 있는, 순서가 있는 콜렉션 (가변 배열)
        let assets : NSMutableArray = NSMutableArray()
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: isOrderedByCreationDate)]
        
        guard let collection = self.photos?.firstObject else {
            return
        }
        
        for indexPath in selectedCells {
            let asset = PHAsset.fetchAssets(in: collection, options: fetchOptions).object(at: indexPath.row)
            assets.add(asset)
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets)
        }, completionHandler: { isDeleted, _ in if isDeleted { self.selectedCells = [] }})
    }
    
    @IBAction func touchUpShareToolbarItem(_ sender: UIBarButtonItem) {
        var sharedPhotos: [UIImage] = []
        
        for indexPath in selectedCells {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell else {
                return
            }
            
            guard let photo = cell.imageView.image else {
                return
            }
            
            sharedPhotos.append(photo)
        }
        
        let activityViewController = UIActivityViewController(activityItems: sharedPhotos, applicationActivities: nil)
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func touchUpOrderBarItem() {
        if self.orderItem.title == "최신순" {
            self.orderItem.title = "과거순"
            self.isOrderedByCreationDate = true
        } else {
            self.orderItem.title = "최신순"
            self.isOrderedByCreationDate = false
        }
        
        // 애니메이션 없이 새로 고침
        OperationQueue.main.addOperation {
            self.collectionView.performBatchUpdates({
                let indexSet = IndexSet(integer: 0)
                self.collectionView.reloadSections(indexSet)
            }, completion: nil)
        }
    }
    
    @IBAction func touchUpSelectButton(_ sender: UINavigationItem) {
        guard let itemTitle = sender.title else {
            preconditionFailure("선택 버튼 정보 조회 오류")
        }
        
        let actionItem = self.toolbar.items?.first
        let trashItem = self.toolbar.items?.last
        
        if itemTitle == "선택" {
            sender.title = "취소"
            self.navigationItem.title = "항목 선택"
            self.isSelectMode = true
            self.orderItem.isEnabled = false
        } else {
            sender.title = "선택"
            self.navigationItem.title = self.albumTitle
            self.isSelectMode = false
            self.selectedCells = []
            self.collectionView.reloadData()
            self.orderItem.isEnabled = true
            actionItem?.isEnabled = false
            trashItem?.isEnabled = false
        }
    }
    
    func requestCollection() {
        guard let title = self.albumTitle else {
            preconditionFailure("선택한 앨범을 찾을 수 없음")
        }
        
        var photos: PHFetchResult<PHAssetCollection>? = nil
        // Q. 사진을 불러오는 부분과 불러온 사진을 사용하는 부분(func collectionView)이 다른데 이때는 어떻게 비동기 처리를 해야하나요?
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
        
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        var length: CGFloat = floor((width - 10) / 3.0)
        
        // 가로 모드일 때
        if width > height {
            length = floor((height - 10) / 3.0)
        }
        
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.minimumLineSpacing = 5
        flowLayout.itemSize = CGSize(width: length, height: length)
        
        self.collectionView.collectionViewLayout = flowLayout
        
        // 유저의 모든 Photo Assets을 불러오기 위해
        PHPhotoLibrary.shared().register(self)
    }
}

extension AlbumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = self.collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell else {
            return
        }
        
        // 선택 모드일 때
        if self.isSelectMode {
            // 이미 선택된 셀일 때
            if self.selectedCells.contains(indexPath) {
                self.selectedCells = self.selectedCells.filter { $0 != indexPath }
                cell.layer.borderWidth = 0
                cell.imageView.alpha = 1
            // 선택된 셀이 아닐 때
            } else {
                self.selectedCells.append(indexPath)
                cell.layer.borderWidth = 2
                cell.imageView.alpha = 0.75
            }
            
            let actionItem = self.toolbar.items?.first
            let trashItem = self.toolbar.items?.last
            
            if self.selectedCells.count > 0 {
                self.navigationItem.title = "\(self.selectedCells.count)장 선택"
                actionItem?.isEnabled = true
                trashItem?.isEnabled = true
            } else {
                self.navigationItem.title = "항목 선택"
                actionItem?.isEnabled = false
                trashItem?.isEnabled = false
            }
        // 선택 모드가 아닐 때, 다음 화면으로 이동
        } else {
            /* init(name:... 에서의 name은 info.plist에 있는 'Main storyboard file base name'의 값
            view controller의 identifier는 storyboard에서 지정해줬음
            단순히 그냥 let detailViewController = DetailViewController()로 생성하면 view의 outlet들이 연결되지 않음
            Interface Builder creates customized instances of your classes and encodes those instances into NIBs and Storyboards for repeated decoding, it doesn't define the classes themselves. */
            guard let detailViewController = UIStoryboard.init(name: "Main", bundle: .main).instantiateViewController(identifier: "detailViewController") as? DetailViewController else {
                return
            }
            
            guard let collection = self.photos?.firstObject else {
                return
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: isOrderedByCreationDate)]
            
            detailViewController.asset = PHAsset.fetchAssets(in: collection, options: fetchOptions).object(at: indexPath.row)
            
            self.navigationController?.pushViewController(detailViewController, animated: true)
        }
    }
}

extension AlbumViewController: UICollectionViewDataSource {
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
        imageOption.isSynchronous = true
        
        let length = cell.frame.width
        
        imageManager.requestImage(for: photo,
                                  targetSize: CGSize(width: length, height: length),
                                  contentMode: .aspectFill,
                                  options: imageOption,
                                  resultHandler: { image, _ in
                                    cell.imageView.image = image
        })
        
        // 다중 선택시 테두리 표시
        cell.layer.borderColor = UIColor.red.cgColor
        
        if self.isSelectMode && self.selectedCells.contains(indexPath) {
            cell.layer.borderWidth = 2
            cell.imageView.alpha = 0.75
        } else {
            cell.layer.borderWidth = 0
            cell.imageView.alpha = 1
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos?.firstObject?.photosCount ?? 0
    }
}

extension AlbumViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // 애니메이션 없이 새로 고침
        OperationQueue.main.addOperation {
            self.collectionView.performBatchUpdates({
                let indexSet = IndexSet(integer: 0)
                self.collectionView.reloadSections(indexSet)
            }, completion: nil)
        }
    }
}
