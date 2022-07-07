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
        let predicate1 = NSPredicate(format: "latitude == %@", latitude)
        let predicate2 = NSPredicate(format: "longitude == %@", longitude)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1,predicate2])

        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(String(describing: pin))-photos")
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    //MARK: Properties
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var photos: [Data] = []
    
    //MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    //MARK: Actions
    
    @IBAction func newCollectionButtonPressed(_ sender: Any) {
        
    }
    
    //MARK: Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        createPin(latitude: latitude, longitude: longitude)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = true
        setupFetchedResultsController()
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
        FlickrClient.photoRequest { response, error in
            self.handlePhotoRequestResponse(response:response,error: error,annotation:annotation)
        }
    }
    
   
    
}
//TODO: you need to figure out how is your model structures, at the moment it seems its getting a collection of Pins with subset of photos collections, we need to get collection of photos for this particular pin
extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: Collection View Delegate Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let aPin = fetchedResultsController.object(at: indexPath).photos?.anyObject()
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.defaultReuseIdentifier, for: indexPath) as! PhotoCell
       
        
        //Configure cell
        cell.imageView.image = UIImage(systemName: "photo.fill")
        
        if (fetchedResultsController.sections?[0].numberOfObjects)! > 0 {
            cell.imageView.image = UIImage(data: aPin as! Data)
        }
//            FlickrClient.downloadingPhotos(server: currentCollection.server, id: currentCollection.id, secret: currentCollection.secret) { data, error in
//                guard let data = data else {
//                    return
//                }
//                DispatchQueue.main.async {
//                    let image = UIImage(data: data)
//                    cell.imageView.image = image
//                    cell.setNeedsLayout()
//                }
//            }
           
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
       // let collection = CollectionModel.collections[0].photoCollection[indexPath.item]
        
        
    }
    
    fileprivate func handlePhotoRequestResponse(response: FlickrResponse?, error: Error?,annotation: MKPointAnnotation) {
        if let response = response {
            for photo in response.photos.photo {
                FlickrClient.downloadingPhotos(server: photo.server, id: photo.id, secret: photo.secret) { data, error in
                    guard let data = data else {
                        return
                    }
                    self.photos.append(data)
                }
            }
            addPin(photos: self.photos)
        } else {
            print("PhotoCollection could not be created!\(error!.localizedDescription)")
        }
    }
    
}
