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
        let predicate = NSPredicate(format: "pin == %@", pin)
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
    var savedPhotos: Bool!
    
    //MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    //MARK: Actions
    @IBAction func newCollectionButtonPressed(_ sender: Any) {
        newCollectionButton.isEnabled = false
        deletingObjectsFromCoreData(objects: pin.corePhotos!)
        deletingObjectsFromCoreData(objects: pin.coreURLs!)
        downloadingNewImageURLs()
    }
    
    //MARK: Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        createPinForMap(latitude: pin.latitude, longitude: pin.longitude)
        debugPrint("Are There any saved photos during viewWillAppear: \(savedPhotos!)")
        
    }
    
    override func viewDidLoad() {
        //setupFetchedResultsController()
        super.viewDidLoad()
        navigationController?.navigationBar.isTranslucent = true
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
    
    func createPinForMap(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate.latitude = latitude
        annotation.coordinate.longitude = longitude
        
        mapView.addAnnotation(annotation)
        mapView.setCenter(annotation.coordinate, animated: true)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
        
    }
    
    fileprivate func downloadingNewImageURLs() {
        FlickrClient.photoRequest(latitude:pin.latitude,longitude:pin.longitude) { response, error in
            if let response = response {
                let downloadedURLs = response.photos.photo
                
                let coreUrls = downloadedURLs.map { flickrPhoto -> CoreURL in
                    let coreItem = CoreURL(context: self.dataController.viewContext)
                    coreItem.url = FlickrClient.Endpoints.photoURL(flickrPhoto.server, flickrPhoto.id, flickrPhoto.secret).url
                    return coreItem
                }
                
                self.pin.addToCoreURLs(NSOrderedSet(array: coreUrls))
                try? self.dataController.viewContext.save()
                self.savedPhotos = false
                self.collectionView.reloadData()
                self.newCollectionButton.isEnabled = true
            } else {
                print("PhotoCollection could not be created!\(error!.localizedDescription)")
            }
        }
    }
}


