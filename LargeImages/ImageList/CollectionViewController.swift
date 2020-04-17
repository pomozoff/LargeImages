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

    override func loadView() {
        view = collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionLayout.itemSize = itemSize

        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        collectionLayout.itemSize.width = collectionView.bounds.width / CGFloat(numberOfColumns)
            - collectionLayout.minimumInteritemSpacing * CGFloat(numberOfColumns - 1)
    }

    // MARK: - Private

    private let numberOfColumns = 3
    private let itemSize = CGSize(width: 100.0, height: 100.0)

    private lazy var collectionLayout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)

    private var disposeBag = DisposeBag()
}

// MARK: - ViewModelOwning

extension CollectionViewController: ViewModelOwning {
    func configure(with viewModel: CollectionViewModel) {
        disposeBag = DisposeBag()
        self.viewModel = viewModel

        viewModel
            .didUpdateDataSource { change in
                // TODO: Update collection
            }
            .disposed(by: disposeBag)

        collectionView.dataSource = self
        collectionView.delegate = self
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
