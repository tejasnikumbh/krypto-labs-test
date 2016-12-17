//
//  BBus.swift
//  Buslo
//
//  Created by Tejas  Nikumbh on 16/12/16.
//  Copyright © 2016 Tejas  Nikumbh. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper

class BBus: Mappable {
    var id: Int?
    var busId: String?
    var name: String?
    var description: String?
    var number: String?
    var destination: String?
    var direction: String?
    
    required init?(map: Map) {
        
    }
    
    // Mappable
    func mapping(map: Map) {
        id               <- map["id"]
        busId            <- map["busId"]
        name             <- map["name"]
        description      <- map["description"]
        number           <- map["number"]
        destination      <- map["destination"]
        direction        <- map["direction"]
    }
}
