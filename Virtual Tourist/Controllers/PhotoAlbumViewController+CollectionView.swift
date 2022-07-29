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
//        if dataController.viewContext.hasChanges {
//            collectionView.reloadData()
//        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.defaultReuseIdentifier, for: indexPath) as! PhotoCell
        
        returnSavedImagesOrURLs(savedPhotos: savedPhotos, indexPath, cell)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        pin.removeFromCoreURLs(at: indexPath.item)
        pin.removeFromCorePhotos(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
        // Apologies i am not sure what do you mean here, as it works perfectly fine at the moment, apart from when you press it 6th or 7th time in a row. The whole collections view doesnt seem to be refreshing and deletion animation works fine.
    
    }
    
    //MARK: Helper Methods
    fileprivate func returnSavedImagesOrURLs(savedPhotos: Bool, _ indexPath: IndexPath, _ cell: PhotoCell) {
        switch savedPhotos {
        case false:
            let coreUrl = pin.coreURLs?.object(at: indexPath.item) as! CoreURLs
            //Configure cell
            cell.imageView.image = UIImage(systemName: "photo.fill")
            cell.activityIndicator.startAnimating()
            if let url = coreUrl.url {
                FlickrClient.downloadingPhotosFromCore(url: url) { data, error in
                    if let data = data {
                        let image = UIImage(data: data)
                        cell.imageView.image = image
                        cell.activityIndicator.stopAnimating()
                        cell.activityIndicator.isHidden = true
                        let coreImage = CorePhoto(context: self.dataController.viewContext)
                        coreImage.corePhoto = data
                        self.pin.addToCorePhotos(coreImage)
                        self.saveContext()
                    }
                }
            }
        case true:
            let coreImage = pin.corePhotos?.object(at: indexPath.item) as! CorePhoto
            DispatchQueue.main.async {
                if let data = coreImage.corePhoto {
                    cell.activityIndicator.stopAnimating()
                    cell.activityIndicator.isHidden = true
                    //Configure cell
                    cell.imageView.image = UIImage(data: data)
                }
            }
        }
    }
    
}
// MARK: Data Controller Methods
extension PhotoAlbumViewController {
    
    func saveContext() {
        try? dataController.viewContext.save()
    }
    
    func deletingObjectsFromCoreData(objects: NSOrderedSet) {
        let context = dataController.viewContext
        
        for object in objects {
            context.delete(object as! NSManagedObject)
        }
        saveContext()
    }
    
}
