//
//  Constants.swift
//  VirtualTourist
//
//  Created by Ravi Kumar Venuturupalli on 8/19/18.
//  Copyright © 2018 Ravi Kumar Venuturupalli. All rights reserved.
//

struct Flickr {
    static let APIScheme = "https"
    static let APIHost = "api.flickr.com"
    static let APIPath = "/services/rest"
    
    static let SearchBBoxHalfWidth = 1.0
    static let SearchBBoxHalfHeight = 1.0
    static let SearchLatRange = (-90.0, 90.0)
    static let SearchLonRange = (-180.0, 180.0)
}

struct FlickrParameterKeys {
    static let Method = "method"
    static let APIKey = "api_key"
    static let GalleryID = "gallery_id"
    static let Extras = "extras"
    static let Format = "format"
    static let NoJSONCallback = "nojsoncallback"
    static let SafeSearch = "safe_search"
    static let Text = "text"
    static let BoundingBox = "bbox"
    static let Page = "page"
}

struct FlickrParameterValues {
    static let SearchMethod = "flickr.photos.search"
    static let APIKey = "b2809678e4fe6f56378acbb2c8b0c5b3"
    static let ResponseFormat = "json"
    static let DisableJSONCallback = "1"
    static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
    static let GalleryID = "5704-72157622566655097"
    static let MediumURL = "url_m"
    static let UseSafeSearch = "1"
}


struct FlickrResponseKeys {
    static let Status = "stat"
    static let Photos = "photos"
    static let Photo = "photo"
    static let Title = "title"
    static let MediumURL = "url_m"
    static let Pages = "pages"
    static let Total = "total"
}

struct FlickrResponseValues {
    static let OKStatus = "ok"
}
