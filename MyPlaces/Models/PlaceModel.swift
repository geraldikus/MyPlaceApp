//
//  PlaceModel.swift
//  MyPlaces
//
//  Created by Anton on 13.04.23.
//

import RealmSwift

class Place: Object {
    
   @objc dynamic var name = ""
   @objc dynamic var location: String?
   @objc dynamic var type: String?
   @objc dynamic var imageData: Data?
   @objc dynamic var date = Date()
    @objc dynamic var rating = 0.0
    
    convenience init(name: String, location: String?, type: String?, imageData: Data?, rating: Double) {
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
}
