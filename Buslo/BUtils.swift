//
//  BUtils.swift
//  Buslo
//
//  Created by Tejas  Nikumbh on 15/12/16.
//  Copyright © 2016 Tejas  Nikumbh. All rights reserved.
//

import UIKit

typealias BOkHandler = () -> ()

final class BUtils {
    
    /*
     * Method : dialog
     *
     * Discussion: Returns a simple display dialog alert view controller
     */
    static func dialog(title: String? = "Buslo", message: String,
                       completion: BOkHandler? = nil) -> UIAlertController {
        let dialog = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: {
                (alertAction) in
                guard let completion = completion else { return }
                completion()
        })
        dialog.addAction(ok)
        return dialog
    }
}
