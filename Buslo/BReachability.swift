//
//  BReachability.swift
//  Permutive
//
//  Created by Tejas Nikumbh on 9/24/16.
//  Copyright © 2016 Tejas Nikumbh. All rights reserved.
//
//  Discussion:
//      This class is responsible for returning if the networking is available
//  or not. 
//

import SystemConfiguration

// MARK:- BReachability Utility Class
final internal class BReachability: BSingleton {
    
    static let sharedInstance = BReachability()
    // Ensures that instances of this aren't created
    fileprivate init() {}
    
    // MARK:- BReachability Internal Methods
    /*
     * isConnectedToNetwork
     *
     * Discussion:
     *     Method that returns if the application on the user's device is connec
     * -ted to network or not.
     */
    func isConnectedToNetwork() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
}
