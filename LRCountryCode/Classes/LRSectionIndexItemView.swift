//
//  LRSectionIndexItemView.swift
//  LRCountryCode
//
//  Created by huawt on 2022/8/22.
//

import Foundation
import UIKit

class LRSectionIndexItemView: UIView {
    var section: Int = 0
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .black
        label.highlightedTextColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.contentView)
        self.contentView.addSubview(self.backgroundImageView)
        self.contentView.addSubview(self.titleLabel)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func set(highlighted: Bool, animated: Bool) {
        self.titleLabel.isHighlighted = highlighted
        self.backgroundImageView.isHighlighted = highlighted
    }
    
    func set(selected: Bool, animated: Bool) {
        self.set(highlighted: selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = self.bounds
        self.backgroundImageView.frame = self.contentView.bounds
        self.titleLabel.frame = self.contentView.bounds
    }
}
