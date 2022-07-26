//
//  PhotoAlbumViewController+Extension.swift
//  Virtual Tourist
//
//  Created by Aleksandrs Trubacs on 04/07/2022.
//

import UIKit
import MapKit
import CoreData

let myImageDownloadQueue = DispatchQueue(label: "com.virtualtourist.image_download_queue")

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: Collection View Delegate Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return pin.coreURLs?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if dataController.viewContext.hasChanges {
            collectionView.reloadData()
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.defaultReuseIdentifier, for: indexPath) as! PhotoCell
        
        returnSavedImagesOrURLs(indexPath, cell)
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageToDelete = pin.coreURLs?.object(at: indexPath.item)
        dataController.viewContext.delete(imageToDelete as! NSManagedObject)
        collectionView.deleteItems(at: [indexPath])
    }
    
    //MARK: Helper Methods
    fileprivate func returnSavedImagesOrURLs(_ indexPath: IndexPath, _ cell: PhotoCell) {
        switch pin.corePhotos!.count > 0 {
        case false:
            let coreUrl = pin.coreURLs?.object(at: indexPath.item) as! CoreURLs
            //Configure cell
            cell.imageView.image = UIImage(systemName: "photo.fill")
            if let url = coreUrl.url {
                    FlickrClient.downloadingPhotosFromCore(url: url) { data, error in
                        if let data = data {
                            let image = UIImage(data: data)
                            cell.imageView.image = image
                            self.saveContext()
                        }
                    }
            }
        case true:
            let coreImage = pin.corePhotos?.object(at: indexPath.item) as! UIImage
            //Configure cell
            cell.imageView.image = coreImage
        }
    }
    
}
// MARK: Data Controller Methods
extension PhotoAlbumViewController {
    
    func saveContext() {
        try? dataController.viewContext.save()
    }
    
    
}
