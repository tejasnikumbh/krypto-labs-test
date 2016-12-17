//
//  BProtocols.swift
//  Buslo
//
//  Created by Tejas  Nikumbh on 15/12/16.
//  Copyright © 2016 Tejas  Nikumbh. All rights reserved.
//

import Foundation


protocol BSingleton: class {
    static var sharedInstance: Self { get }
}

