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
    
    static func searchByLatLon (latitude: Double, longitude: Double) {
        
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
    
    func searchPhotos(_ pageNumber: Int = 1, latitude: Double, longitude: Double, completionForSearch : @escaping (_ results: FlickrSearchResults?, _ error : NSError?) -> Void){
       
        let bboxValues = bboxString(latitude: latitude, longitude: longitude)
        print("bbox values are: \(bboxValues)")
        
        let session = URLSession.shared
        
        let parameters = [FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
                                FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey, FlickrParameterKeys.BoundingBox: bboxValues,
                                FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback, FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
                                FlickrParameterKeys.Page: pageNumber,
                                FlickrParameterKeys.PerPage: FlickrParameterValues.PerPage,
                                FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch] as [String : Any]
        let url: URL = createFlickrURLFromParameters(parameters as [String : AnyObject])
        
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
            
            let responseString = String(data: data!, encoding: .utf8)
            //print("responseString = \(String(describing: responseString))")
            
            var parsedResult: AnyObject! = nil
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as AnyObject
                //print("Parsed result: \(parsedResult)")
            } catch {   
                _ = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(String(describing: data))'"]
                print("JSON data error: \(data!)")
            }
            
            guard let photosContainer = parsedResult[FlickrResponseKeys.Photos] as? [String:AnyObject], let photosRecevied = photosContainer[FlickrResponseKeys.Photo] as? [[String:AnyObject]] else{
                print("No key called Photo in Json data")
                sendError(error: "No key called Photo in Json data")
                return
            }
            
            var flickrPhotos = [FlickrPhoto]()
            
            for photoObject in photosRecevied {
                guard let photoID = photoObject[FlickrResponseKeys.PhotoID] as? String,
                let farm = photoObject[FlickrResponseKeys.PhotoFarm] as? Int,
                let server = photoObject[FlickrResponseKeys.PhotoServer] as? String,
                    let secret = photoObject[FlickrResponseKeys.PhotoSecret] as? String else {
                        break
                }
                
                let flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)
                guard let url = flickrPhoto.flickrImageURL(), let imageData = try? Data(contentsOf: url as URL) else {
                    break
                }
                
                if let image = UIImage(data: imageData) {
                    flickrPhoto.thumbnail = image
                    flickrPhoto.largeImage = image
                    flickrPhotos.append(flickrPhoto)
                }
            }
            completionForSearch(FlickrSearchResults(searchResults: flickrPhotos), nil)
            
        })
         task.resume()
    }
    
    func searchPhotosSingle(_ pageNumber: Int = 1, latitude: Double, longitude: Double, completionForSearch : @escaping (_ results: [URL]?, _ error : NSError?) -> Void){
        
        let bboxValues = bboxString(latitude: latitude, longitude: longitude)
        print("bbox values are: \(bboxValues)")
        
        let session = URLSession.shared
        
        let parameters = [FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
                          FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey, FlickrParameterKeys.BoundingBox: bboxValues,
                          FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback, FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
                          FlickrParameterKeys.Page: pageNumber,
                          FlickrParameterKeys.PerPage: FlickrParameterValues.PerPage,
                          FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch] as [String : Any]
        let url: URL = createFlickrURLFromParameters(parameters as [String : AnyObject])
        
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
            
            let responseString = String(data: data!, encoding: .utf8)
            //print("responseString = \(String(describing: responseString))")
            
            var parsedResult: AnyObject! = nil
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as AnyObject
                //print("Parsed result: \(parsedResult)")
            } catch {
                _ = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(String(describing: data))'"]
                print("JSON data error: \(data!)")
            }
            
            guard let photosContainer = parsedResult[FlickrResponseKeys.Photos] as? [String:AnyObject], let photosRecevied = photosContainer[FlickrResponseKeys.Photo] as? [[String:AnyObject]] else{
                print("No key called Photo in Json data")
                sendError(error: "No key called Photo in Json data")
                return
            }
            
            //var flickrPhotos = [FlickrPhoto]()
            
            var result_urls: [URL] = []
            
            for photoObject in photosRecevied {
                guard let photoID = photoObject[FlickrResponseKeys.PhotoID] as? String,
                    let farm = photoObject[FlickrResponseKeys.PhotoFarm] as? Int,
                    let server = photoObject[FlickrResponseKeys.PhotoServer] as? String,
                    let secret = photoObject[FlickrResponseKeys.PhotoSecret] as? String else {
                        break
                }
                
//                let flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)
//                guard let url = flickrPhoto.flickrImageURL(), let imageData = try? Data(contentsOf: url as URL) else {
//                    break
//                }
//
//                if let image = UIImage(data: imageData) {
//                    flickrPhoto.thumbnail = image
//                    flickrPhoto.largeImage = image
//                    flickrPhotos.append(flickrPhoto)
//                }
                
                let flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)
                guard let url = flickrPhoto.flickrImageURL() else {
                    break
                }
                result_urls.append(url)
            }
            //completionForSearch(FlickrSearchResults(searchResults: flickrPhotos), nil)
            completionForSearch(result_urls, nil)
            
        })
        task.resume()
    }
    
    
}
