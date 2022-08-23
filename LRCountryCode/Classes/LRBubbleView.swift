//
//  LRBubbleView.swift
//  LRCountryCode
//
//  Created by huawt on 2022/8/22.
//

import Foundation
import UIKit

class LRBubbleView: UIView {
    var indexString: String = "" {
        didSet {
            self.indexLabel.text = indexString
        }
    }
    var backgroundImage: String = "" {
        didSet {
            self.imageView.image = UIImage(contentsOfFile: backgroundImage)
        }
    }
    private lazy var indexLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24)
        label.backgroundColor = .clear
        return label
    }()
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        
        self.addSubview(self.imageView)
        self.addSubview(self.indexLabel)
        
    }
    
    override func layoutSubviews() {
        if #available(iOS 11.0, *) {
            let position = (UIScreen.main.bounds.height - safeAreaInsets.top - 80) / 2 + 58
            self.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: position, width: 44, height: 44)
        } else {
            let position = (UIScreen.main.bounds.height - 64 - 80) / 2 + 58
            self.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: position, width: 44, height: 44)
        }
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
