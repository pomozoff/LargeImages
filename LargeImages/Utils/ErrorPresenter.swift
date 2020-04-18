//
//  ErrorPresenter.swift
//  LargeImages
//
//  Created by Anton Pomozov on 17.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

public typealias Action = () -> Void

public protocol ErrorPresenter where Self: UIViewController {
    func presentError(_ message: String, actions: [UIAlertAction])
    func presentErrorWithDismiss(_ message: String, completion: Action?)
}

public extension ErrorPresenter {
    func presentError(_ message: String, actions: [UIAlertAction]) {
        let alert = UIAlertController(
            title: NSLocalizedString("Error", comment: "Title of the standard dialog with an error"),
            message: message,
            preferredStyle: .alert
        )

        actions.forEach(alert.addAction)
        present(alert, animated: true, completion: nil)
    }

    func presentErrorWithDismiss(_ message: String, completion: Action?) {
        presentError(
            message,
            actions: [UIAlertAction(
                title: NSLocalizedString("OK", comment: "Title of the OK action of the standard dialog with an error"),
                style: .default,
                handler: { _ in completion?() })
            ]
        )
    }
}
