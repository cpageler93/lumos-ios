//
//  LargeButton.swift
//  23Angle
//
//  Created by Christoph Pageler on 09.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import UIKit


@IBDesignable
class LargeButton: UIButton {

    override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        return CGSize(width: superSize.width, height: 48)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.size.height / 3
        layer.masksToBounds = true
    }

}
