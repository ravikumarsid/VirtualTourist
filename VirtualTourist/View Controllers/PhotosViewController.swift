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
    var thumbnailImages: [PhotoThumbnail]?
    var thumbnailUIImages: [UIImage] = []
    
    
    var fetchedResultsController: NSFetchedResultsController<PhotoThumbnail>!
    var dataController: DataController!
    fileprivate let reuseIdentifier = "FlickrCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 10.0, right: 10.0)
    fileprivate var searchResults = [FlickrSearchResults]()
    fileprivate var flickrAPIDataLoaded = false
    fileprivate var flickrAPIPageNumber: Int = 1
    fileprivate let flickr = FlickrClient()
    fileprivate let itemsPerRow: CGFloat = 3
    var selectedCell = [IndexPath]()
    var numberOfPhotoObjects: Int = 0
    
    
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
        
        print("Does this pin have photos attached, count: \(String(describing:  self.numberOfPhotoObjects))")
        //print("Collection view cell bounds: \(photoCollectionView)")
        
        
        if ((self.pin.photos?.anyObject()) != nil) {
            if (((self.pin.photos?.count)!) == 0) {
                DispatchQueue.main.async {
                    self.noImages.isHidden = false
                    self.newCollectionButton.isEnabled = false
                }
            } else {
                print("Calling core data")
                fetchThumbnailsCoreData()
            }
        } else {
            print("Calling FLickr")
            fetchFlickrPhotos()
        }
        //fetchFlickrPhotos()
        
        DispatchQueue.main.async {
            self.miniMapView.addAnnotation(annotation)
            self.miniMapView.setRegion(coordinateRegion, animated: false)
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
        if ((self.pin.photos?.anyObject()) != nil) {
            return 1
        } else{
            print("Number of sections is: \(searchResults.count)")
            return searchResults.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if ((self.pin.photos?.anyObject()) != nil) {
            return thumbnailUIImages.count
        } else{
            return searchResults[section].searchResults.count
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickrPhotoCell
        
        
        
        
        if ((self.pin.photos?.anyObject()) != nil) {
            
            cell.activityIndicator.stopAnimating()
            let thumbailImage = thumbnailUIImages[indexPath.item]
            cell.backgroundColor = UIColor.white
            cell.imageView.image = thumbailImage
        }
        
        else {
            print("Inside else")
            
            let flickrPhoto = photoForIndexPath(indexPath: indexPath)
            cell.backgroundColor = UIColor.white
            cell.imageView.image = flickrPhoto.thumbnail
            cell.activityIndicator.stopAnimating()
//            cell.activityIndicator.startAnimating()
//            thumbnailUIImages.removeAll()
//            self.newCollectionButton.isEnabled = false
//
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
    
    func saveThumbnailsToCoreData() {
        let imagesResults = self.searchResults[0].searchResults
        var thumbnails: [UIImage] = []
        
        for imageResult in imagesResults {
            thumbnails.append(imageResult.thumbnail!)
            thumbnailUIImages.append(imageResult.thumbnail!)
            
            guard let thumbnailData = UIImageJPEGRepresentation(imageResult.thumbnail!, 1) else {
                print("JPG error")
                return
            }
            
            
            let thumbnailForPin = PhotoThumbnail(context: dataController.viewContext)
            thumbnailForPin.imageData = thumbnailData
            thumbnailForPin.pin = pin
        }
        try? dataController.viewContext.save()
        print("Number of images to save is: \(thumbnails.count)")
    }
    
    func fetchThumbnailsCoreData() {
        let fetchRequest:NSFetchRequest<PhotoThumbnail> = PhotoThumbnail.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            thumbnailImages = result
        }
        print("From core data get thumbnails: \(String(describing: thumbnailImages?.count))")
        
        for thumbnailImage in thumbnailImages! {
            if let image = UIImage(data: thumbnailImage.imageData!) {
                thumbnailUIImages.append(image)
            }
        }
        
        print("UI Images count: \(String(describing: thumbnailUIImages.count))")
        DispatchQueue.main.async {
            self.photoCollectionView.reloadData()
            self.newCollectionButton.isEnabled = true
        }
    }
    
    func fetchFlickrPhotos() {
        thumbnailUIImages.removeAll()
        let spinnerView = UIViewController.displaySpinner(onView: self.view)
        self.newCollectionButton.isEnabled = false
        print("Page number is: \(self.flickrAPIPageNumber)")
        FlickrClient.sharedInstance.searchPhotos(self.flickrAPIPageNumber, latitude: (self.latitude?.doubleValue)!, longitude: (self.longitude?.doubleValue)!) { results, error in
            
            UIViewController.removeSpinner(spinner: spinnerView)
            //self.flickrAPIDataLoaded = true
            
            if let error = error {
                print(error)
                if error.localizedDescription == "The device is not connected to the internet." {
                    self.displayAlert(alertTitle: "Check Internet connection", alertMesssage: "The device is not connected to the internet.")
                }
                return
            }
            
            if let results = results {
                print("Found \(results.searchResults.count)")
                
                if (results.searchResults.count == 0) {
                    
                    DispatchQueue.main.async {
                        self.noImages.isHidden = false
                        self.newCollectionButton.isEnabled = false
                    }
                    return
                } else {
                    self.searchResults.insert(results, at: 0)
                    self.flickrAPIDataLoaded = true
                    self.saveThumbnailsToCoreData()
                }
                
                
            }
            DispatchQueue.main.async {
                self.photoCollectionView.reloadData()
                self.newCollectionButton.isEnabled = true
                
            }
            
        }
    }
    
    func deletePhotosFromCoreData(){
        if ((self.pin.photos?.anyObject()) != nil) {
            
            var thumbnailImagesDel: [PhotoThumbnail]?
            
            let fetchRequest:NSFetchRequest<PhotoThumbnail> = PhotoThumbnail.fetchRequest()
            let predicate = NSPredicate(format: "pin == %@", pin)
            fetchRequest.predicate = predicate
            
            if let result = try? dataController.viewContext.fetch(fetchRequest) {
                thumbnailImagesDel = result
            }
            print("For new collection, from core data delete all existing thumbnails: \(String(describing: thumbnailImagesDel?.count))")
            thumbnailUIImages.removeAll()
            
            for thumbnailToDelete in thumbnailImagesDel! {
                dataController.viewContext.delete(thumbnailToDelete)
            }
            try? dataController.viewContext.save()
            self.photoCollectionView.reloadData()
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
                    
                    var thumbnailImagesDel: [PhotoThumbnail]?
                    
                    let fetchRequest:NSFetchRequest<PhotoThumbnail> = PhotoThumbnail.fetchRequest()
                    let predicate = NSPredicate(format: "pin == %@", pin)
                    fetchRequest.predicate = predicate
                    
                    if let result = try? dataController.viewContext.fetch(fetchRequest) {
                        thumbnailImagesDel = result
                    }
                    print("For deletion from core data get thumbnails: \(String(describing: thumbnailImagesDel?.count))")
                    
                    
                    
                    var indexesToRemove: [IndexPath] = []
                    for indexPath in selectedItemPaths {
                        indexesToRemove.append(indexPath)
                    }
                    indexesToRemove.sort()
                    
                    let reversedIndexesToRemove = Array(indexesToRemove.reversed())
                    
                    if selectedItemPaths.count > 0 {
                        if selectedItemPaths.count == self.photoCollectionView.numberOfItems(inSection: 0) {
                            print("Deleting all photos in section")
                            thumbnailUIImages.removeAll()
                            deletePhotosFromCoreData()
                            //self.photoCollectionView.reloadItems(at: selectedItemPaths)
                            self.photoCollectionView.reloadData()
                        }
                        else {
                            print("If number of items is greater than zero")
                            print("Number of indexes to remove: \(reversedIndexesToRemove.count)")
                            for index in reversedIndexesToRemove {
                                print("Number of items is in thumbnailsUI: \(thumbnailUIImages.count) an index to remove is: \(index)")
                                thumbnailUIImages.remove(at: index.item)
                                print("Core Data thumbnails count is: \(String(describing: thumbnailImagesDel?.count)) and index to delete is: \(index.item)")
                                let photoForDel = thumbnailImagesDel?[index.item]
                                thumbnailImagesDel?.remove(at: index.item)
                                
                                dataController.viewContext.delete(photoForDel!)
                            }
                            try? dataController.viewContext.save()
                            self.photoCollectionView.deleteItems(at: indexesToRemove)
                        }
                    }
                    
                    
                }
                
            } else {
                if let selectedItemPaths = photoCollectionView.indexPathsForSelectedItems {
                    
                    var indexesToRemove: [IndexPath] = []
                    for indexPath in selectedItemPaths {
                        indexesToRemove.append(indexPath)
                    }
                    
                    indexesToRemove.sort()
                    
                    let reversedIndexesToRemove = Array(indexesToRemove.reversed())
                    
                    if selectedItemPaths.count > 0 {
                        for index in reversedIndexesToRemove {
                            let photoToRemove = photoForIndexPath(indexPath: index)
                            
                            let filteredResults = searchResults[(index as NSIndexPath).section].searchResults.filter( {
                                $0 != photoToRemove
                            })
                            self.searchResults.removeAll()
                            
                            var flickrPhotos = [FlickrPhoto]()
                            for flickrPhoto in filteredResults {
                                flickrPhotos.append(flickrPhoto)
                            }
                            self.searchResults.insert(FlickrSearchResults(searchResults: flickrPhotos), at: 0)
                        }
                    }
                    self.photoCollectionView.deleteItems(at: indexesToRemove)
                }
            }
            
            
            DispatchQueue.main.async {
                self.newCollectionButton.setTitle("New Collection", for: UIControlState.normal)
            }
            
        }
            //New Collection
        else {
            self.flickrAPIPageNumber += 1
            deletePhotosFromCoreData()
            self.searchResults.removeAll()
            fetchFlickrPhotos()
            // saveThumbnailsToCoreData()
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


private extension PhotosViewController {
    func photoForIndexPath (indexPath: IndexPath) -> FlickrPhoto{
        return searchResults[(indexPath as NSIndexPath).section].searchResults[(indexPath as IndexPath).row]
    }
}


