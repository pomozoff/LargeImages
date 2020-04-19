//
//  ImageListViewController.swift
//  LargeImages
//
//  Created by Anton Pomozov on 15.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

class ImageListViewController: UIViewController {
    private(set) var viewModel: ImageListViewModel?

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        currentViewModel.fetchImages()
    }

    // MARK: - Private

    private let numberOfColumns = 2
    private let itemSize = CGSize(width: 100.0, height: 100.0)

    private lazy var collectionLayout = PinterestLayout(numberOfColumns: 2)
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)

    private lazy var activityIndicatorView = UIView()
    private lazy var activityIndicator = UIActivityIndicatorView()
}

// MARK: - ViewModelOwning

extension ImageListViewController: ViewModelOwning {
    func configure(with viewModel: ImageListViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - UICollectionViewDataSource

extension ImageListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel?.numberOfItems ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ImageCell = collectionView.dequeueReusableCell(at: indexPath)
        cell.setup(for: indexPath)

        cell.cancelToken = currentViewModel.makeImageCellViewModel(
            for: indexPath.item,
            with: collectionLayout.columnWidth
        ) { cellViewModel in
            guard cell.indexPath == indexPath else {
                if let oldCell = collectionView.cellForItem(at: indexPath) as? ImageCell {
                    return oldCell.configure(with: cellViewModel)
                }
                return
            }

            cell.configure(with: cellViewModel)
        }

        return cell
    }
}

// MARK: - PinterestLayoutDelegate

extension ImageListViewController: PinterestLayoutDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        heightForPhotoAtIndexPath indexPath: IndexPath
    ) -> CGFloat {
        currentViewModel.sizeOfImage(for: indexPath.item, with: collectionLayout.columnWidth).height
    }
}

// MARK: - ImagePresenter

extension ImageListViewController: ImagePresenter {
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

extension ImageListViewController: ErrorPresenter {}

// MARK: - Private

private extension ImageListViewController {
    func setup() {
        view.backgroundColor = .systemBackground

        collectionLayout.delegate = self

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true

        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        collectionView.dataSource = self

        activityIndicator.color = .white
        activityIndicator.style = .large
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        activityIndicatorView.alpha = 0.0
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.isUserInteractionEnabled = false
        activityIndicatorView.backgroundColor = UIColor(white: 0.3, alpha: 0.5)

        activityIndicatorView.addSubview(activityIndicator)
        view.addSubview(collectionView)
        view.addSubview(activityIndicatorView)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: activityIndicatorView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: activityIndicatorView.centerYAnchor),

            collectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

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
