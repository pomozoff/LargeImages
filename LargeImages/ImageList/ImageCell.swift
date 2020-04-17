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

    private let imageView = UIImageView()
    private let placeholderImage = UIImage(named: "placeholder")
}

extension ImageCell: ViewModelOwning {
    func configure(with viewModel: ImageCellViewModel) {
        imageView.image = viewModel.image
    }
}

private extension ImageCell {
    func setup() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        prepareForReuse()

        contentView.backgroundColor = .systemBackground
        contentView.clipsToBounds = true
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}
