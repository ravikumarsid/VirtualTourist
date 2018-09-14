//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Ravi Kumar Venuturupalli on 8/19/18.
//  Copyright © 2018 Ravi Kumar Venuturupalli. All rights reserved.
//

import UIKit
import Foundation

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient()
    
    static func searchForPhotosWithLatLong (latitude: Double, longitude: Double, completionForFinalImage: @escaping (_ foundImage: Bool, _ image: UIImage) -> Void) {
        
        let parameters = [FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
                          FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey, FlickrParameterKeys.BoundingBox: FlickrClient.init().bboxString(latitude: latitude, longitude: longitude),
                          FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback,
                          FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
                          FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
                          FlickrParameterKeys.PerPage: FlickrParameterValues.PerPage,
                          FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch] as [String : Any]
        
        FlickrClient.init().searchFlickrPhotos(parameters as [String : AnyObject]) { (foundImage, image) in
            if foundImage {
                completionForFinalImage(foundImage, image)
            } else {
                return
            }
        }
    }
    
    private func createFlickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL{
        var components =  URLComponents()
        components.scheme = Flickr.APIScheme
        components.host = Flickr.APIHost
        components.path = Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, val) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(val)")
            components.queryItems?.append(queryItem)
        }
        return components.url!
    }
    
    func bboxString(latitude: Double, longitude: Double) -> String{
        
        let minimumLon = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    func searchFlickrPhotos(_ methodParameters: [String:AnyObject], completionForPhotoSearch : @escaping (_ resultsFound: Bool, _ image: UIImage) -> Void){
       
        let session = URLSession.shared
        let url: URL = createFlickrURLFromParameters(methodParameters)
        
        var request = URLRequest(url: url)
        
        let task = session.dataTask(with: request, completionHandler:  { (data, response, error) in
            
            func sendError(error: String) {
                _ = [NSLocalizedDescriptionKey: error]
            }
            
            if Reachability.isConnectedToNetwork() != true {
                sendError(error: "The device is not connected to the internet!")
                return
            }
            
            guard (error == nil) else {
                sendError(error: "There was a error in your request: \(String(describing: error))")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError(error: "Your request returned a status code other than 2XX!")
                return
            }
            
            guard data != nil else {
                sendError(error: "No data was returned by the request!")
                return
            }
            
            _ = String(data: data!, encoding: .utf8)
            
            var parsedResult: AnyObject! = nil
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as AnyObject
            } catch {
                _ = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(String(describing: data))'"]
            }
            
            guard let photosContainer = parsedResult[FlickrResponseKeys.Photos] as? [String:AnyObject], let _ = photosContainer[FlickrResponseKeys.Photo] as? [[String:AnyObject]] else{
                print("No key called Photo in Json data")
                sendError(error: "No key called Photo in Json data")
                return
            }
            
            guard let totalPages = photosContainer[FlickrResponseKeys.Pages] as? Int else {
                print("No key called pages in \(photosContainer)")
                return
            }
            
            let pageNumber = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageNumber))) + 1
            
            
            self.searchFlickrSinglePhoto(methodParameters, pageNumber: randomPage, getImage: { (foundPhotos, photos) in
                if foundPhotos {
                    completionForPhotoSearch(true, photos)
                }
            })
        })
        task.resume()
    }
    
    func searchFlickrSinglePhoto(_ parameters: [String:AnyObject], pageNumber: Int, getImage: @escaping(_ foundPhotos: Bool, _ photo: UIImage) -> Void) {
        
        var singlePhoto = UIImage()
        
        var parametersWithpage = parameters
        parametersWithpage[FlickrParameterKeys.Page] = pageNumber as AnyObject?
        
        let session = URLSession.shared
        let url: URL = createFlickrURLFromParameters(parametersWithpage)
        
        var request = URLRequest(url: url)
        let task = session.dataTask(with: request, completionHandler:  { (data, response, error) in
            
            func sendError(error: String) {
                _ = [NSLocalizedDescriptionKey: error]
            }
            
            if Reachability.isConnectedToNetwork() != true {
                sendError(error: "The device is not connected to the internet!")
                return
            }
            
            guard (error == nil) else {
                sendError(error: "There was a error in your request: \(String(describing: error))")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError(error: "Your request returned a status code other than 2XX!")
                return
            }
            
            guard data != nil else {
                sendError(error: "No data was returned by the request!")
                return
            }
            
            _ = String(data: data!, encoding: .utf8)
            
            var parsedResult: AnyObject! = nil

            do {
                parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as AnyObject
            } catch {
                _ = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(String(describing: data))'"]
            }
            
            guard let photosContainer = parsedResult[FlickrResponseKeys.Photos] as? [String:AnyObject], let photosReceived = photosContainer[FlickrResponseKeys.Photo] as? [[String:AnyObject]] else{
                print("No key called Photo in Json data")
                sendError(error: "No key called Photo in Json data")
                return
            }
            
            if photosReceived.count == 0 {
                sendError(error: "No photos found")
                return
            } else {
                let photoRandomIndex = Int(arc4random_uniform(UInt32(photosReceived.count)))
                let photoDictionary = photosReceived[photoRandomIndex] as [String:AnyObject]
                
                guard let imageURL = photoDictionary[FlickrResponseKeys.MediumURL] as? String else {
                    sendError(error: "No key called \(String(describing: photoDictionary[FlickrResponseKeys.MediumURL])) in\(photoDictionary))")
                    return
                }
                
                if let imageData = try? Data(contentsOf: URL(string: imageURL)!) {
                    singlePhoto = UIImage(data: imageData)!
                } else {
                    sendError(error: "No image at the URL \(imageURL)")
                }
                getImage(true, singlePhoto)
            }
            
        })
        task.resume()
    }
}
