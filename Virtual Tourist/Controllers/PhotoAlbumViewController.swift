//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Aleksandrs Trubacs on 18/06/2022.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    //MARK: Core Data Set Up
    var pin: Pin!
    
    var dataController:DataController!
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    //MARK: Properties
    var flickrPhotos: [Photo]!
    var downloadedImages:[UIImage]!
    
    //MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    //MARK: Actions
    
    @IBAction func newCollectionButtonPressed(_ sender: Any) {
        
    }
    
    //MARK: Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        //setupFetchedResultsController()
        createPin(latitude: pin.latitude, longitude: pin.longitude)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = true
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: MKMapview Delegate Methods
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.pinTintColor = .red
            pinView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            pinView?.animatesDrop = true
        }
        else {
            pinView?.annotation = annotation
        }
        return pinView
    }

    //MARK: Helper Methods
    
    func createPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        //mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate.latitude = latitude
        annotation.coordinate.longitude = longitude
        
        self.mapView.addAnnotation(annotation)
        self.mapView.setCenter(annotation.coordinate, animated: true)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
        
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: Collection View Delegate Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("\(flickrPhotos.count) urls in the array")
        return 48
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imageForCell = pin.coreURLs?.object(at: indexPath.item) as! Photo
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.defaultReuseIdentifier, for: indexPath) as! PhotoCell
        
        //Configure cell
        cell.imageView.image = UIImage(systemName: "photo.fill")
        if flickrPhotos.count > 0 {
            DispatchQueue.main.async {
                FlickrClient.downloadingPhotos(server: imageForCell.server, id: imageForCell.id, secret: imageForCell.secret) { data, error in
                    if let data = data {
                        let image = UIImage(data: data)
                        cell.imageView.image = image
                        self.saveContext(image:image!)
                    }
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        FlickrClient.photoRequest(latitude: pin.latitude, longitude: pin.longitude) { response, error in
            if let response = response {
                self.flickrPhotos.remove(at: indexPath.item)
                self.flickrPhotos.insert(response.photos.photo[152], at: indexPath.item)
            }
        }
        collectionView.reconfigureItems(at: [indexPath])
        
//        let imageToDelete = fetchedResultsController.object(at: indexPath)
//        dataController.viewContext.delete(imageToDelete)
        
    }
}
    // MARK: Data Controller Methods
extension PhotoAlbumViewController {
    
    func saveContext(image: UIImage) {
        try? dataController.viewContext.save()
    }
}

