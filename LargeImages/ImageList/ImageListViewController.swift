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
        currentViewModel.startFetchingImages()
    }

    // MARK: - Private

    private let numberOfColumns = 2
    private let itemSize = CGSize(width: 100.0, height: 100.0)

    private lazy var collectionLayout = PinterestLayout(numberOfColumns: numberOfColumns)
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)

    private lazy var activityIndicatorView = UIView()
    private lazy var activityIndicator = UIActivityIndicatorView()

    private lazy var refreshControl = UIRefreshControl()
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
        ) { [weak self] cellViewModel in
            guard cell.indexPath == indexPath else {
                guard let oldCell = collectionView.cellForItem(at: indexPath) as? ImageCell else {
                    return
                }
                return oldCell.configure(with: cellViewModel)
            }
            cell.configure(with: cellViewModel)

            if case .idle = cellViewModel.state {
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0.0,
                    options: .curveEaseInOut,
                    animations: {
                        self?.collectionLayout.invalidateLayout()
                    },
                    completion: nil)
            }
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ImageListViewController: PinterestLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
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

    func didUpdateItems(with diff: CollectionDifference<URL>, updateData: @escaping () -> Void, completion: @escaping () -> Void) {
        collectionView.applyChanges(diff, updateData: updateData, completion: completion)
    }
}

// MARK: - ErrorPresenter

extension ImageListViewController: ErrorPresenter {}

// MARK: - Private Actions

private extension ImageListViewController {
    @objc
    private func refreshImages(_ sender: UIRefreshControl) {
        currentViewModel.refreshImages()
    }
}

// MARK: - Private

private extension ImageListViewController {
//    var itemWidth: CGFloat {
//        (collectionView.bounds.width
//            - collectionLayout.minimumInteritemSpacing * CGFloat(numberOfColumns - 1)
//        ) / CGFloat(numberOfColumns)
//    }

    func setup() {
        view.backgroundColor = .systemBackground

        collectionLayout.delegate = self

        collectionView.refreshControl = refreshControl
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        collectionView.dataSource = self

        refreshControl.addTarget(self, action: #selector(refreshImages), for: .valueChanged)

        activityIndicator.color = .white
        activityIndicator.style = .large
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        activityIndicatorView.alpha = 0.0
        activityIndicatorView.isUserInteractionEnabled = false
        activityIndicatorView.backgroundColor = UIColor(white: 0.3, alpha: 0.5)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

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
        if isShown {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            refreshControl.endRefreshing()
        }

        UIView.animate(withDuration: 0.25) {
            self.activityIndicatorView.alpha = isShown ? 1.0 : 0.0
        }
    }
}
