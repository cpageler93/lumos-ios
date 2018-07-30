//
//  String+Localized.swift
//  Lumos
//
//  Created by Christoph Pageler on 30.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation


extension String {

    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }

}
