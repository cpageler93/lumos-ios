//
//  NavigationControllerRootSegue.swift
//  23Angle
//
//  Created by Christoph Pageler on 09.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import UIKit

class NavigationControllerRootSegue: UIStoryboardSegue {

    override func perform() {
        source.navigationController?.setViewControllers([destination], animated: UIView.areAnimationsEnabled)
    }

}
