//
//  OverviewUploadCollectionReusableView.swift
//  Lumos
//
//  Created by Christoph Pageler on 09.08.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import UIKit


class OverviewUploadCollectionReusableView: UICollectionReusableView {

    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var labelUserInfo: UILabel!
    @IBOutlet var buttonRetry: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        buttonRetry.setTitle("retry".localized(),
                             for: .normal)

        updateInformation()
        NotificationCenter.default.addObserver(forName: HTTPService.didUpdateUploadsNotification,
                                               object: nil, queue: OperationQueue.main)
        { notification in
            self.updateInformation()
        }
    }

    private func updateInformation() {
        let uploadingCount = HTTPService.shared.imageUploads.filter({ $0.status == .uploading }).count
        let failedCount = HTTPService.shared.imageUploads.filter({ $0.status == .failed }).count

        var text = ""
        if uploadingCount > 0 {
            let photosString = uploadingCount == 1 ? "singular_photo".localized() : "plural_photo".localized()
            let localized = String(format: "uploading_photo".localized(), "\(uploadingCount) \(photosString)")
            text = "\(text) \(localized)"
        }
        if failedCount > 0 {
            let photosString = uploadingCount == 1 ? "singular_photo".localized() : "plural_photo".localized()
            text = "\(text) \(failedCount) \(photosString) \("failed".localized())"
        }
        labelUserInfo.text = text

        if uploadingCount > 0 {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
        buttonRetry.alpha = failedCount > 0 ? 1 : 0
    }
    
    @IBAction func actionRetry(_ sender: UIButton) {
        HTTPService.shared.retryFailedUploads()
    }

}
