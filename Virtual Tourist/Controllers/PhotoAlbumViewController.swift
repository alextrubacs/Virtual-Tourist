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
        let predicate1 = NSPredicate(format: "latitude == %@", "\(latitude)")
        let predicate2 = NSPredicate(format: "longitude == %@", "\(longitude)")
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[predicate1,predicate2])
        fetchRequest.predicate = compoundPredicate
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin-photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            print("Fetched Objects results: \(fetchedResultsController.fetchedObjects!.count)")
            pin = fetchedResultsController.fetchedObjects![0]
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    //MARK: Properties
    var latitude: Double!
    var longitude: Double!
    var flickrPhotos: [FlickrPhoto]!
    
    //MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    //MARK: Actions
    
    @IBAction func newCollectionButtonPressed(_ sender: Any) {
        
    }
    
    //MARK: Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        setupFetchedResultsController()
        createPin(latitude: latitude, longitude: longitude)
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
    
    fileprivate func checkForSavedPhotos() -> [UIImage] {
        if pin.photos?.count != nil && pin.photos!.count > 0 {
            return pin.photos!.allObjects as! [UIImage]
        } else {
            return []
        }
    }
}
extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: Collection View Delegate Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("\(flickrPhotos.count) urls in the array")
        return flickrPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photoUrl = flickrPhotos[indexPath.item]
        let savedPhotos = checkForSavedPhotos()[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.defaultReuseIdentifier, for: indexPath) as! PhotoCell
        
        //Configure cell
        cell.imageView.image = UIImage(systemName: "photo.fill")
        
        if flickrPhotos.count > 0 {
            if flickrPhotos.count == pin.photos?.count {
                print("\(pin.photos!.count) photos saved in a Pin")
                DispatchQueue.main.async {
                    cell.imageView.image = savedPhotos
                }
            } else {
                DispatchQueue.main.async {
                    FlickrClient.downloadingPhotos(server: photoUrl.server, id: photoUrl.id, secret: photoUrl.secret) { data, error in
                        if let data = data {
                            let image = UIImage(data: data)
                            cell.imageView.image = image
                            self.saveContext(data: data)
                        }
                    }
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // let collection = CollectionModel.collections[0].photoCollection[indexPath.item]
        
        
    }
    
    
    
}
    // MARK: Data Controller Methods
extension PhotoAlbumViewController {
    
    func saveContext(data: Data) {
        self.pin.photos?.adding(UIImage(data: data)!)
        try? dataController.viewContext.save()
    }
    
}

