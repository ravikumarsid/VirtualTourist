//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Ravi Kumar Venuturupalli on 8/12/18.
//  Copyright © 2018 Ravi Kumar Venuturupalli. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var miniMapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    @IBOutlet weak var noImages: UITextField!
    var latitude: NSString?
    var longitude: NSString?
    var pin: Pin!
    
    var fetchedResultsController: NSFetchedResultsController<PhotoThumbnail>!
    
    var dataController: DataController!
    fileprivate let reuseIdentifier = "FlickrCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 10.0, right: 10.0)
    
    fileprivate var flickrAPIDataLoaded = false
    fileprivate var flickrAPIPageNumber: Int = 1
    fileprivate let flickr = FlickrClient()
    fileprivate let itemsPerRow: CGFloat = 3
    var thumbnailImages: [UIImage]?
    var selectedCell = [IndexPath]()
    var numberOfPhotoObjects: Int = 0
    var collectionSize = 21
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.miniMapView.delegate = self
        self.photoCollectionView.allowsMultipleSelection = true
        self.noImages.isHidden = true
        self.numberOfPhotoObjects = (self.pin.photos?.count)!
        
        self.miniMapView.isScrollEnabled = false
        self.miniMapView.isZoomEnabled = false
        self.miniMapView.isRotateEnabled = false
        self.miniMapView.isPitchEnabled = false
        
        let coordinate = CLLocationCoordinate2D(latitude: (latitude?.doubleValue)!, longitude: (longitude?.doubleValue)!)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        let regionRadius: CLLocationDistance = 2000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        
        setupFetchedResultsController()
        
        if ((self.pin.photos?.anyObject()) != nil) {
            if (((self.pin.photos?.count)!) == 0) {
                DispatchQueue.main.async {
                    self.noImages.isHidden = false
                    self.newCollectionButton.isEnabled = false
                }
            }
        }
        
        DispatchQueue.main.async {
            self.miniMapView.addAnnotation(annotation)
            self.miniMapView.setRegion(coordinateRegion, animated: false)
        }
        
    }
    
    func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<PhotoThumbnail> = PhotoThumbnail.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try? fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.flickrAPIPageNumber = 1
        
        if ((self.pin.photos?.anyObject()) != nil) {
            if dataController.viewContext.hasChanges {
                try? dataController.viewContext.save()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.flickrAPIPageNumber = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        fetchedResultsController = nil
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {return nil}
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = false
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if fetchedResultsController.sections?[0].numberOfObjects == 0 {
            return collectionSize
        } else {
            collectionSize = (fetchedResultsController.sections?[0].numberOfObjects)!
            return collectionSize
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickrPhotoCell
        
        cell.backgroundColor = UIColor.darkGray
        
        if indexPath.row >= (fetchedResultsController.fetchedObjects?.count)! {
            cell.imageView.image = nil
            cell.activityIndicator.startAnimating()
            
            FlickrClient.searchForPhotosWithLatLong(latitude: (self.latitude?.doubleValue)!, longitude: (self.longitude?.doubleValue)!) { (foundImage, image) in
                self.thumbnailImages?.append(image)
                if foundImage {
                    DispatchQueue.main.async {
                        cell.imageView.image = image
                        cell.activityIndicator.stopAnimating()
                        let photo = PhotoThumbnail(context: self.dataController.viewContext)
                        
                        let imageData: Data? = UIImagePNGRepresentation(image)
                        photo.imageData = imageData
                        photo.creationDate = Date()
                        photo.pin = self.pin
                        
                        try? self.dataController.viewContext.save()
                    }
                }
            }
            
        } else {
            let coreDataImage = fetchedResultsController.object(at: indexPath)
            cell.imageView.image = UIImage(data: coreDataImage.imageData!)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickrPhotoCell
        
        newCollectionButton.setTitle("Remove Selected Pictures", for: UIControlState.normal)
        self.checkSelectedCellsCount()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.checkSelectedCellsCount()
    }
    
    func displayAlert(alertTitle: String, alertMesssage: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: alertTitle, message: alertMesssage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func checkSelectedCellsCount() {
        if let selectedItemPaths = photoCollectionView.indexPathsForSelectedItems {
            if selectedItemPaths.count > 0 {
                DispatchQueue.main.async {
                    self.newCollectionButton.setTitle("Remove Selected Pictures", for: UIControlState.normal)
                }
            } else {
                DispatchQueue.main.async {
                    self.newCollectionButton.setTitle("New Collection", for: UIControlState.normal)
                }
            }
        }
    }
    
    @IBAction func okButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func newCollectionTapped(_ sender: Any) {
        
        if newCollectionButton.currentTitle == "Remove Selected Pictures" {
            
            if ((self.pin.photos?.anyObject()) != nil) {
                //Remove selected pictures from core data
                if let selectedItemPaths = photoCollectionView.indexPathsForSelectedItems {
                    var indexesToRemove: [IndexPath] = []
                    for indexPath in selectedItemPaths {
                        indexesToRemove.append(indexPath)
                    }
                    indexesToRemove.sort()
                    
                    let reversedIndexesToRemove = Array(indexesToRemove.reversed())
                    
                    if selectedItemPaths.count > 0 {
                        if selectedItemPaths.count == self.photoCollectionView.numberOfItems(inSection: 0) {
                            if let numberPhotosToDelete = fetchedResultsController.fetchedObjects?.count {
                                for num in 0...numberPhotosToDelete-1 {
                                    let photoToDelete = fetchedResultsController.object(at: IndexPath(row: num, section: 0))
                                    dataController.viewContext.delete(photoToDelete)
                                }
                                
                                try? dataController.viewContext.save()
                                self.thumbnailImages?.removeAll()
                                collectionSize = 21
                                photoCollectionView.reloadData()
                            }
                        }
                        else {
                            for index in reversedIndexesToRemove {
                                let photoForDel = fetchedResultsController.object(at: IndexPath(row: index.row, section: 0))
                                thumbnailImages?.remove(at: index.row)
                                
                                dataController.viewContext.delete(photoForDel)
                            }
                            try? dataController.viewContext.save()
                            self.photoCollectionView.deleteItems(at: indexesToRemove)
                        }
                    }
                    
                }
            }
            
            DispatchQueue.main.async {
                self.newCollectionButton.setTitle("New Collection", for: UIControlState.normal)
            }
        }
            //New Collection
        else {
            if let numberPhotosToDelete = fetchedResultsController.fetchedObjects?.count {
                for num in 0...numberPhotosToDelete-1 {
                    let photoToDelete = fetchedResultsController.object(at: IndexPath(row: num, section: 0))
                    dataController.viewContext.delete(photoToDelete)
                }
                
                try? dataController.viewContext.save()
                self.thumbnailImages?.removeAll()
                collectionSize = 21
                photoCollectionView.reloadData()
            }
        }
    }
}

extension PhotosViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}


extension PhotosViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            break
        case .delete:
            break
        case .update:
            break
        case .move:
            break
        default:
            break
        }
    }
}


