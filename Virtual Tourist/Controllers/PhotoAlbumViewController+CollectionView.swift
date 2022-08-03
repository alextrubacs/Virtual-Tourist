//
//  PhotoAlbumViewController+Extension.swift
//  Virtual Tourist
//
//  Created by Aleksandrs Trubacs on 04/07/2022.
//

import UIKit
import MapKit
import CoreData

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    // MARK: Collection View Delegate Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return pin.corePhotos?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.defaultReuseIdentifier, for: indexPath) as! PhotoCell
        returnSavedImagesOrURLs(savedPhotos: savedPhotos, indexPath, cell)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        pin.removeFromCoreURLs(at: indexPath.item)
       // pin.removeFromCorePhotos(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
    }
    
    //MARK: Helper Methods
    fileprivate func returnSavedImagesOrURLs(savedPhotos: Bool, _ indexPath: IndexPath, _ cell: PhotoCell) {
        switch savedPhotos {
        case false:
            let coreUrl = pin.coreURLs?.object(at: indexPath.item) as! CorePhoto
            //Configure cell
            cell.imageView.image = UIImage(systemName: "photo.fill")
            cell.activityIndicator.startAnimating()
            if let url = coreUrl.coreURL {
                FlickrClient.downloadingPhotosFromCore(url: url) { data, error in
                    if let data = data {
                        let image = UIImage(data: data)
                        cell.imageView.image = image
                        cell.activityIndicator.stopAnimating()
                        cell.activityIndicator.isHidden = true
                        coreUrl.corePhoto = data
                        self.saveContext()
                        self.limitDownload()
                    }
                }
            }
        case true:
            let coreImage = pin.coreURLs?.object(at: indexPath.item) as! CorePhoto
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
    fileprivate func limitDownload() {
        if self.pin.corePhotos!.count <= 18 {return} else {self.savedPhotos = true}
        self.collectionView.reloadData()
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
