//
//  BRoute.swift
//  Buslo
//
//  Created by Tejas  Nikumbh on 16/12/16.
//  Copyright © 2016 Tejas  Nikumbh. All rights reserved.
//

import ObjectMapper

class BRoute: Mappable {
    
    var points: [[Double]]?
    
    required init?(map: Map) {
        
    }
    
    // Mappable
    func mapping(map: Map) {
        points <- map["points"]
    }
}
