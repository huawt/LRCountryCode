//
//  LRSectionIndexView.swift
//  LRCountryCode
//
//  Created by huawt on 2022/8/22.
//

import Foundation
import UIKit


protocol LRSectionIndexViewDataSource: NSObjectProtocol {
    func sectionIndexView(_ sectionIndexView: LRSectionIndexView, itemViewFor section: Int) -> LRSectionIndexItemView
    func numberOfItemViewFor(sectionIndexView: LRSectionIndexView) -> Int
    
    func sectionIndexView(_ sectionIndexView: LRSectionIndexView, calloutViewFor section: Int) -> UIView
    func sectionIndexView(_ sectionIndexView: LRSectionIndexView, titleFor section: Int) -> String
}

protocol LRSectionIndexViewDelegate: NSObjectProtocol {
    func sectionIndexView(_ sectionIndexView: LRSectionIndexView, didSelected section: Int)
}

enum LRSectionIndexCalloutDirection: Int {
    case left
    case right
}

enum LRCalloutViewType: Int {
    case forQQMusic
    case forUserDefined
}

class LRSectionIndexView: UIView {
    weak var dataSource: LRSectionIndexViewDataSource?
    weak var delegate: LRSectionIndexViewDelegate?
    //选中提示图显示的方向，相对于LRSectionIndexView的对象而言
    var calloutDirection: LRSectionIndexCalloutDirection = .left
    // 是否显示选中提示图
    var isShowCallount: Bool = true
    //选中提示图的样式,默认是QQ音乐的样式
    var calloutViewType: LRCalloutViewType = .forQQMusic
    //itemView的高度，默认是根据itemView的数目均分LRSectionIndexView的对象的高度
    var fixedItemHeight: CGFloat = 0
    //选中提示图与LRSectionIndexView的对象边缘的距离
    var calloutMargin: CGFloat = 0
    
    let kBackgroundViewLeftMargin: CGFloat = 3
    
    private var itemViewHeight: CGFloat = 0
    private var highlightedItemIndex: Int = -1
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()
    
    private lazy var calloutView: UIView? = {
        let view = UIView()
        return view
    }()
    
    var itemViewList: [LRSectionIndexItemView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.backgroundView)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    func reloadItemViews() {
        for view in self.itemViewList {
            view.removeFromSuperview()
        }
        self.itemViewList.removeAll()
        
        let numberOfItems: Int = self.dataSource?.numberOfItemViewFor(sectionIndexView: self) ?? 0
        for index in 0 ..< numberOfItems {
            if let itemView = self.dataSource?.sectionIndexView(self, itemViewFor: index) {
                itemView.section = index
                self.itemViewList.append(itemView)
                self.addSubview(itemView)
            }
        }
        self.layoutItemViews()
    }
    func setBackgroundViewFrame() {
        self.backgroundView.frame = CGRect(x: kBackgroundViewLeftMargin, y: 0, width: self.frame.width - kBackgroundViewLeftMargin * 2, height: self.frame.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layoutItemViews()
    }
    
    func layoutItemViews() {
        if self.itemViewList.isEmpty == false {
            itemViewHeight = self.frame.height / CGFloat(self.itemViewList.count)
        }
        if self.fixedItemHeight > 0 {
            itemViewHeight = self.fixedItemHeight
        }
        var offsetY: CGFloat = 0
        for view in self.itemViewList {
            view.frame = CGRect(x: 0, y: offsetY, width: self.frame.width, height: itemViewHeight)
            offsetY += itemViewHeight
        }
    }
    
    func highlightItem(for section: Int) {
        guard section < self.itemViewList.count else { return }
        self.unhighlightAllItems()
        let itemView = self.itemViewList[section]
        itemView.set(highlighted: true, animated: true)
    }
    
    func unhighlightAllItems() {
        if self.isShowCallount {
            self.calloutView?.removeFromSuperview()
            self.calloutView = nil
        }
        self.itemViewList.forEach { view in
            view.set(highlighted: false, animated: false)
        }
    }
    
    func selectItemView(for section: Int) {
        guard section < self.itemViewList.count else { return }
        self.highlightItem(for: section)
        let selectedSectionView: LRSectionIndexItemView = self.itemViewList[section]
        var centerY = selectedSectionView.center.y
        if self.isShowCallount {
            if self.calloutViewType == .forUserDefined, let calloutView = self.dataSource?.sectionIndexView(self, calloutViewFor: section) {
                let titleStr = self.dataSource?.sectionIndexView(self, titleFor: section) ?? ""
                self.calloutView = calloutView
                self.calloutView?.isHidden = titleStr.isEmpty == true
                self.addSubview(calloutView)
                
                if (centerY - calloutView.frame.height / 2) < 0 {
                    centerY = calloutView.frame.height / 2
                }
                if selectedSectionView.center.y + calloutView.frame.height / 2 > itemViewHeight * CGFloat(self.itemViewList.count) {
                    centerY = itemViewHeight * CGFloat(self.itemViewList.count) - calloutView.frame.height / 2
                }
            } else {
                self.calloutView?.frame = CGRect(x: 0, y: 0, width: 88, height: 51)
                let imageView = UIImageView(image: UIImage(named: ""))
                imageView.frame = self.calloutView!.bounds
                self.calloutView?.addSubview(imageView)
                
                let tipLabel = UILabel(frame: CGRect(x: 10, y: (self.calloutView!.frame.height - 30) / 2, width: 30, height: 30))
                tipLabel.backgroundColor = UIColor.clear
                tipLabel.textColor = UIColor.red
                tipLabel.font = UIFont.boldSystemFont(ofSize: 36)
                tipLabel.textAlignment = NSTextAlignment.center
                tipLabel.text = self.dataSource?.sectionIndexView(self, titleFor: section) ?? ""
                self.calloutView!.addSubview(tipLabel)
                self.addSubview(self.calloutView!)
                
                self.calloutMargin = -18
            }
        }
        
        switch self.calloutDirection {
        case .left:
            self.calloutView?.center = CGPoint(x: -(self.calloutView!.frame.width / 2 + self.calloutMargin), y: centerY)
        case .right:
            self.calloutView!.center = CGPoint(x: selectedSectionView.frame.width + self.calloutView!.frame.width / 2 + self.calloutMargin, y: centerY)
        }
        
        self.delegate?.sectionIndexView(self, didSelected: section)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundView.isHidden = false
        let touchPoint = touches.first!.location(in: self)
        
        for itemView in self.itemViewList {
            if itemView.frame.contains(touchPoint) {
                self.selectItemView(for: itemView.section)
                highlightedItemIndex = itemView.section
                return
            }
        }
        highlightedItemIndex = -1
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundView.isHidden = false
        let touchPoint = touches.first!.location(in: self)
        
        for itemView in self.itemViewList {
            if itemView.frame.contains(touchPoint) {            
                if itemView.section != highlightedItemIndex {
                    self.selectItemView(for: itemView.section)
                    highlightedItemIndex = itemView.section
                    return
                }
            }
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.backgroundView.isHidden = true
            self?.unhighlightAllItems()
            self?.highlightedItemIndex = -1
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesCancelled(touches, with: event)
    }
}
