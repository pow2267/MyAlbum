//
//  AlbumViewController.swift
//  MyAlbum
//
//  Created by kwon on 2021/08/19.
//

import UIKit

class AlbumViewController: UIViewController {
    
    var albumTitle: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = self.albumTitle
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
