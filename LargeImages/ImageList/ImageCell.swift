//
//  ImageCell.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

class ImageCell: UICollectionViewCell {
    private(set) var viewModel: ImageCellViewModel?
    private(set) var indexPath: IndexPath = [-1, -1]

    var cancelToken: CancelToken?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        imageView.image = placeholderImage
    }

    func setup(for indexPath: IndexPath) {
        updateState(.fetching)

        cancelToken?()
        cancelToken = nil
        viewModel = nil

        self.indexPath = indexPath
    }

    private let imageView = UIImageView()
    private let placeholderImage = UIImage(named: "placeholder")
    private let errorImage = UIImage(named: "error")

    private let activityIndicatorView = UIView()
    private let activityIndicator = UIActivityIndicatorView()
}

extension ImageCell: ViewModelOwning {
    func configure(with viewModel: ImageCellViewModel) {
        self.viewModel = viewModel

        updateState(viewModel.state)

        guard let image = viewModel.image else { return }

        imageView.image = image
        cancelToken = nil
    }
}

private extension ImageCell {
    func setup() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.backgroundColor = .systemBackground
        contentView.clipsToBounds = true

        activityIndicator.color = .white
        activityIndicator.style = .large
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        activityIndicatorView.alpha = 0.0
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.isUserInteractionEnabled = false
        activityIndicatorView.backgroundColor = UIColor(white: 0.3, alpha: 0.5)

        activityIndicatorView.addSubview(activityIndicator)
        contentView.addSubview(imageView)
        contentView.addSubview(activityIndicatorView)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: activityIndicatorView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: activityIndicatorView.centerYAnchor),

            activityIndicatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            activityIndicatorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            activityIndicatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            activityIndicatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        prepareForReuse()
    }

    func showActivityIndicator(_ isShown: Bool) {
        isShown ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()

        UIView.animate(withDuration: 0.25) {
            self.activityIndicatorView.alpha = isShown ? 1.0 : 0.0
        }
    }

    func updateState(_ state: FetchingState) {
        switch state {
        case .idle:
            showActivityIndicator(false)

        case .fetching:
            showActivityIndicator(true)

        case .error:
            showActivityIndicator(false)
            imageView.image = errorImage
        }
    }
}
