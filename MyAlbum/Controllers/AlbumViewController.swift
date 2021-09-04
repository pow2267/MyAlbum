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
    
    var assetCollection: PHAssetCollection?
    var assets: PHFetchResult<PHAsset>?
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    var isOrderedByCreationDate: Bool = false
    var isSelectMode: Bool = false
    var selectedCells: [IndexPath] = []
    
    @IBAction func touchUpTrashToolbarItem(_ sender: UIBarButtonItem) {
        guard let collection = self.assetCollection else {
            return
        }
        
        // NSMutableArray: 동적으로 크기를 변경할 수 있는, 순서가 있는 콜렉션 (가변 배열)
        let assets : NSMutableArray = NSMutableArray()
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: isOrderedByCreationDate)]
        
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
        /* review: 미리 애셋들을 fetch하도록 변경한 경우 여기서 한 번 더 변경된 Order로 fetch해주어야합니다.
         Q. fetch를 한 번 더 해야한다고 하셨는데, 밑에서 collectionView를 reload해주고 있고, reload할 때 변경된
         isOrderedByCreationDate를 이용해 다시 한 번 fetch하기 때문에 여기서는 하지 않아도 괜찮지 않을까요?*/
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
            self.navigationItem.title = self.assetCollection?.localizedTitle
            self.isSelectMode = false
            self.selectedCells = []
            self.collectionView.reloadData()
            self.orderItem.isEnabled = true
            actionItem?.isEnabled = false
            trashItem?.isEnabled = false
        }
    }
    
    func requestCollection() {
        
        guard let collection = self.assetCollection else {
            return
        }
                
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: self.isOrderedByCreationDate)]
                
        self.assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = self.assetCollection?.localizedTitle
        
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
            
            guard let collection = self.assetCollection else {
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
        
        guard let collection = self.assetCollection else {
            preconditionFailure("앨범 불러오기 오류")
        }
        
        // Q. ViewController에서와 마찬가지로 셀 속 이미지들이 깜빡이면서 바뀌는 듯한 현상이 나타납니다. 비동기 처리가 원인일까요?
        OperationQueue().addOperation {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: self.isOrderedByCreationDate)]
            
            let photo = PHAsset.fetchAssets(in: collection, options: fetchOptions).object(at: indexPath.row)
            
            let imageOption: PHImageRequestOptions = PHImageRequestOptions()
            imageOption.resizeMode = .exact
            imageOption.isSynchronous = true
            
            OperationQueue.main.addOperation {
                self.imageManager.requestImage(for: photo,
                                          targetSize: CGSize(width: cell.frame.width, height: cell.frame.height),
                                          contentMode: .aspectFill,
                                          options: imageOption,
                                          resultHandler: { image, _ in
                                            DispatchQueue.main.async {
                                                cell.imageView.image = image
                                            }
                })
                
                // review: main thread에서 수행될 수 있도록 수정해야 합니다.
                // 다중 선택시 테두리 표시
                DispatchQueue.main.async {
                    cell.layer.borderColor = UIColor.red.cgColor
                    
                    if self.isSelectMode && self.selectedCells.contains(indexPath) {
                        cell.layer.borderWidth = 2
                        cell.imageView.alpha = 0.75
                    } else {
                        cell.layer.borderWidth = 0
                        cell.imageView.alpha = 1
                    }
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assets?.count ?? 0
    }
}

extension AlbumViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // review: 미리 fetch하는 경우 변경사항을 기존 fetchResult에 반영해줘야 합니다.
        guard let assets = self.assets, let newAssets = changeInstance.changeDetails(for: assets)?.fetchResultAfterChanges else {
            return
        }

        self.assets = newAssets
        
        // 애니메이션 없이 새로 고침
        OperationQueue.main.addOperation {
            self.collectionView.performBatchUpdates({
                let indexSet = IndexSet(integer: 0)
                self.collectionView.reloadSections(indexSet)
            }, completion: nil)
        }
    }
}
