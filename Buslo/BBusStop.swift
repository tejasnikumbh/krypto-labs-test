//
//  BBusStop.swift
//  Buslo
//
//  Created by Tejas  Nikumbh on 15/12/16.
//  Copyright © 2016 Tejas  Nikumbh. All rights reserved.
//

import UIKit
import MapKit

class BBusStop: NSObject, MKAnnotation {
    
    let title: String?
    var subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let busStopId: Int
    
    init(title: String, subtitle: String,
         coordinate: CLLocationCoordinate2D, busStopId: Int) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.busStopId = busStopId
        super.init()
    }
    
}
