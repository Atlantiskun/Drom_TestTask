//
//  CardItemCell.swift
//  Drom
//
//  Created by Дмитрий Болучевских on 10.02.2022.
//

import UIKit

class CardItemCell: UICollectionViewCell {
    
    static let identifier = "CardItemCollectionViewCell"
    
    private let cardImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cardImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cardImageView.frame = contentView.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cardImageView.image = nil
    }
    
    public func configure(with image: UIImage) {
        cardImageView.image = image
    }
    
}
