//
//  ThumbnailView.swift
//  Zenbil
//
//  Created by Berhan Witte on 26.05.24.
//

import UIKit

class ThumbnailBarView: UIView {
    var thumbnails: [UIImage] = [] {
        didSet {
            setupThumbnails()
        }
    }
    var onThumbnailTap: ((Int) -> Void)?
    var onAddButtonTap: (() -> Void)?

    private let stackView = UIStackView()
    private let addButton = UIButton(type: .contactAdd)

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setupStackView()
        setupAddButton()
    }

    private func setupStackView() {
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    private func setupAddButton() {
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(addButton)
    }

    private func setupThumbnails() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, image) in thumbnails.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.tag = index
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 8
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(thumbnailTapped(_:)))
            imageView.addGestureRecognizer(tapGesture)
            stackView.addArrangedSubview(imageView)
        }
        stackView.addArrangedSubview(addButton)
    }

    @objc private func thumbnailTapped(_ sender: UITapGestureRecognizer) {
        if let index = sender.view?.tag {
            onThumbnailTap?(index)
        }
    }

    @objc private func addButtonTapped() {
        onAddButtonTap?()
    }
}
