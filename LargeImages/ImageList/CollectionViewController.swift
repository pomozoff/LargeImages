//
//  CollectionViewController.swift
//  LargeImages
//
//  Created by Anton Pomozov on 15.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

class CollectionViewController: UIViewController {
    private(set) var viewModel: CollectionViewModel?

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        currentViewModel.fetchImages()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let width = (collectionView.bounds.width
            - collectionLayout.minimumInteritemSpacing * CGFloat(numberOfColumns - 1)
        ) / CGFloat(numberOfColumns)

        collectionLayout.itemSize.width = width
        collectionLayout.itemSize.height = width
    }

    // MARK: - Private

    private let numberOfColumns = 2
    private let itemSize = CGSize(width: 100.0, height: 100.0)

    private lazy var collectionLayout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)

    private lazy var activityIndicatorView = UIView()
    private lazy var activityIndicator = UIActivityIndicatorView()
}

// MARK: - ViewModelOwning

extension CollectionViewController: ViewModelOwning {
    func configure(with viewModel: CollectionViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - UICollectionViewDataSource

extension CollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel?.numberOfItems ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ImageCell = collectionView.dequeueReusableCell(at: indexPath)

        currentViewModel.imageCellViewModel(for: indexPath.item, size: collectionLayout.itemSize) { cellViewModel in
            guard let cell = collectionView.cellForItem(at: indexPath) as? ImageCell else {
                return
            }
            cell.configure(with: cellViewModel)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CollectionViewController: UICollectionViewDelegateFlowLayout {}

// MARK: - ImagePresenter

extension CollectionViewController: ImagePresenter {
    func updateState(_ state: FetchingState) {
        switch state {
        case .idle:
            showActivityIndicator(false)

        case .fetching:
            showActivityIndicator(true)

        case let .error(error):
            showActivityIndicator(false)
            presentErrorWithDismiss(error.localizedDescription, completion: nil)
        }
    }

    func didUpdateURLs(with diff: CollectionDifference<URL>, updateData: @escaping () -> Void, completion: @escaping () -> Void) {
        collectionView.applyChanges(diff, updateData: updateData, completion: completion)
    }
}

// MARK: - ErrorPresenter

extension CollectionViewController: ErrorPresenter {}

// MARK: - Private

private extension CollectionViewController {
    func setup() {
        collectionLayout.itemSize = itemSize

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground

        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self

        activityIndicator.startAnimating()
        activityIndicator.style = .large
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        activityIndicatorView.addSubview(activityIndicator)

        activityIndicatorView.alpha = 0.0
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.isUserInteractionEnabled = false
        activityIndicatorView.backgroundColor = UIColor(white: 0.3, alpha: 0.5)

        view.addSubview(collectionView)
        view.addSubview(activityIndicatorView)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: activityIndicatorView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: activityIndicatorView.centerYAnchor),

            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            activityIndicatorView.topAnchor.constraint(equalTo: view.topAnchor),
            activityIndicatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            activityIndicatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func showActivityIndicator(_ isShown: Bool) {
        isShown ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()

        UIView.animate(withDuration: 0.25) {
            self.activityIndicatorView.alpha = isShown ? 1.0 : 0.0
        }
    }
}
