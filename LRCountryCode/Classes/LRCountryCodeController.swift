//
//  LRCountryCodeController.swift
//  LRCountryCode
//
//  Created by huawt on 2022/8/22.
//

import Foundation
import UIKit

let kIsIPad: Bool = UI_USER_INTERFACE_IDIOM() == .pad

typealias LRCountryCodeBlock = ((_ countryName: String, _ code: String) -> Void)
typealias AdjustSearchBarStyleBlock = ((_ searchBar: UISearchBar) -> Void)

public protocol LRCountryCodeControllerDelegate: NSObjectProtocol {
    func lrCountry(name: String, code: String)
}

public enum LRCountryCodeType: Int {
    case left
    case right
}

public enum LRCountryCodeLanguage: Int {
    case cn
    case en
    
    var fileName: String {
        switch self {
        case .cn:
            return "SortedNameCH"
        case .en:
            return "SortedNameEH"
        }
    }
    var fileExt: String {
        return "plist"
    }
    
    var navigationTitle: String {
        switch self {
        case .cn:
            return "选择国家和地区"
        case .en:
            return "Select Country Or Area"
        }
    }
}

public class LRCountryCodeController: UIViewController {
    /// 可以使用代理或block把选择的国家地区码返回出去
    weak var delegate: LRCountryCodeControllerDelegate?
    var returnCountryCodeBlock: LRCountryCodeBlock?
    /**
      以下属性为可选，不提供的话都有默认值
    */
    /// 默认值为：选择国家和地区
    var navigationTitle: String {
        return self.language.navigationTitle
    }
    /// 默认值为：取消
    var backBtnTitle: String = "取消"
    /// 默认没有图片。如果要到达只有图片的效果，还要把backBtnTitle设置为@""
    var backBtnImage: UIImage?
    /// 默认值为一个文字为 取消的按钮。如果对此按钮的样式不满意，可以自己传一个按钮。
    var backBtn: UIButton?
    /// 控制隐藏 右边选中字母时放大的气泡。默认显示
    var hideBubbleView: Bool = false
    /// 控制隐藏 右边索引条。默认显示
    var hideSectionIndexView: Bool = false
    /// 控制 是否显示选中图标。默认显示选中图标
    var hideSelectImage: Bool = false
    /// 选中图标。自己传一个
    var selectImage: UIImage? = UIImage(named: "")
    /// 控制 是否滚动到选中的section。默认Yes, 滚动到 选中的section
    var scrollToRowAtIndexPath: Bool = true
    /// 控制 进入搜索状态时是否隐藏导航栏。默认Yes
    var hidesNavigationBarDuringPresentation: Bool = true
    /// 控制 是否隐藏搜索框。默认NO
    var hideSearchBar: Bool = false
    /// 控制 国家码显示在左边还是右边。默认在左边
    var showType: LRCountryCodeType = .left
    /// 国家码的颜色，只有在showType为DXCountryCodeTpyeRight时才能生效。
    var rightCodeColor: UIColor?
    /// 右边索引条的文字的颜色
    var indexViewColor: UIColor?
    /// 右边索引条的文字高亮的颜色
    var highlightedIndexViewColor: UIColor?
    /// 调整SearchBar的样式。searchBar就是searchController.searchBar。
    var adjustSearchBarStyleBlock: AdjustSearchBarStyleBlock?
    /// 多语言
    var language: LRCountryCodeLanguage = .cn
    
    private var tableView: UITableView = UITableView()
    private var searchController: UISearchController = UISearchController()
    private var sortedNameDict: [String: [String]] = [:]
    private var indexArray: [String] = []
    private var results: [String] = []
    
    private var countryCode: String = "86"
    private var selectIndexStr: String = ""
    private var isSearchStrEmpty: Bool = true
    
    private lazy var bubbleView: LRBubbleView = {
        let view = LRBubbleView()
        if let bundle = self.lr_countryCodeBundle() {
            let imagePath: String = bundle.resourcePath!.appending("/icon_letter_index")
            view.backgroundImage = imagePath
        }
        return view
    }()
    private var sectionIndexView: LRSectionIndexView = LRSectionIndexView()
    
    private lazy var selectImageView: UIImageView = {
        var image = self.selectImage
        if image == nil, let bundle = self.lr_countryCodeBundle() {
            let imagePath: String = bundle.resourcePath!.appending("/icon_row_select")
            image = UIImage(contentsOfFile: imagePath)
        }
        let imageView = UIImageView(image: image)
        return imageView
    }()

    /// Use this init method / 用这个初始化方法 。参数格式是@"86"这样的。如果调用init，默认就是86
    public init(with countryCode: String) {
        super.init(nibName: nil, bundle: nil)
        self.countryCode = countryCode
        if self.countryCode.isEmpty == true {
            self.countryCode = "86"
        }
    }
    
    func loadCountryData() {
        guard let bundle = self.lr_countryCodeBundle() else { return }
        guard let path = bundle.path(forResource: self.language.fileName, ofType: self.language.fileExt) else { return }
        guard let dict = NSDictionary(contentsOf: URL(fileURLWithPath: path)) as? [String : [String]] else { return }
        self.sortedNameDict = dict
        self.indexArray = ((dict as NSDictionary).allKeys as! [String]).sorted(by: { $0.compare($1) == .orderedAscending })
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.initNavigationBar()
        
        self.loadCountryData()
        self.createSubviews()
        
        self.addBubbleView()
        self.initIndexView()
        
        self.sectionIndexView.reloadItemViews()
        
        self.setupSelectState()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.refreshIndexView()
        }
    }
    
    func refreshIndexView() {
        if self.searchController.isActive, self.isSearchStrEmpty == false {
            self.sectionIndexView.isHidden = true
        } else {
            self.sectionIndexView.isHidden = false
            
            var size = CGSize(width: 22, height: 18)
            if kIsIPad {
                size = CGSize(width: 22, height: 21)
            }
            
            let margin: CGFloat = kIsIPad ? -20 : 0
            
            let indexViewHeight: CGFloat = CGFloat(self.indexArray.count) * size.height
            self.sectionIndexView.frame = CGRect(x: self.tableView.frame.width - size.width - margin, y: (self.tableView.frame.height - indexViewHeight) / 2 + 20, width: size.width, height: indexViewHeight)
            self.sectionIndexView.setBackgroundViewFrame()
        }
    }
    
    func addBubbleView() {
        guard self.hideBubbleView == false, self.hideSectionIndexView == false else { return }
        self.bubbleView.backgroundColor = .clear
        self.bubbleView.isHidden = true
        if self.bubbleView.superview == nil {
            self.view.addSubview(self.bubbleView)
        }
    }
    
    func initIndexView() {
        guard self.hideSectionIndexView == false else { return }
        self.sectionIndexView.backgroundColor = .clear
        self.sectionIndexView.dataSource = self
        self.sectionIndexView.delegate = self
        self.sectionIndexView.isShowCallount = true
        self.sectionIndexView.calloutViewType = .forUserDefined
        self.sectionIndexView.calloutDirection = .left
        self.sectionIndexView.calloutMargin = 10
        self.view.addSubview(self.sectionIndexView)
        self.view.bringSubview(toFront: self.sectionIndexView)
    }
    
    func setupSelectState() {
        var indexLetter: String = ""
        var selectedRow: Int?
        for item in self.sortedNameDict {
            let strArray: [String] = item.value.compactMap({ $0.components(separatedBy: "+").last! })
            if let index = strArray.firstIndex(of: self.countryCode) {
                selectedRow = index
                indexLetter = item.key
                break
            }
        }
        let selectedSection = self.indexArray.firstIndex(of: indexLetter)
        guard let section = selectedSection, let row = selectedRow else { return }
        self.tableView.reloadData()
        let indexPath = IndexPath(row: row, section: section)
        self.selectIndexStr = self.showCodeString(index: indexPath)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let cell = self?.tableView.cellForRow(at: indexPath)
            if self?.hideSelectImage == false, self?.showType == .left {
                cell?.accessoryView = self?.selectImageView
            }
        }
        if self.scrollToRowAtIndexPath {
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }
    
    func initNavigationBar() {
        self.navigationItem.title = self.navigationTitle
        if let backBtn = backBtn {
            backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        } else {
            self.backBtn = UIButton(type: .custom)
            self.backBtn?.setTitle(self.backBtnTitle, for: .normal)
            self.backBtn?.setImage(self.backBtnImage, for: .normal)
            self.backBtn?.setTitleColor(UIColor.black, for: .normal)
            self.backBtn?.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            self.backBtn?.addTarget(self, action: #selector(goBack), for: .touchUpInside)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.backBtn!)
        }
    }
    
    @objc func goBack() {
        if self.searchController.isActive {
            self.searchController.isActive = false
        }
        self.searchController.searchBar.resignFirstResponder()
        if self.presentingViewController != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.dismiss(animated: true)
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func createSubviews() {
        let tableViewOffset: CGFloat = kIsIPad ? 20 : 0
        let statusBarH: CGFloat = UIApplication.shared.statusBarFrame.height
        self.tableView = UITableView(frame: CGRect(x: 0, y: statusBarH, width: self.view.bounds.width - tableViewOffset, height: self.view.bounds.height - statusBarH), style: .plain)
        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 44
        self.tableView.backgroundColor = .clear
        self.tableView.autoresizingMask = .flexibleWidth
        if #available(iOS 11.0, *) {
            self.tableView.contentInsetAdjustmentBehavior = .automatic
            self.tableView.isOpaque = false
            self.tableView.estimatedRowHeight = 0
            self.tableView.estimatedSectionFooterHeight = 0
            self.tableView.estimatedSectionHeaderHeight = 0
        }
        
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchResultsUpdater = self
        self.searchController.hidesNavigationBarDuringPresentation = self.hidesNavigationBarDuringPresentation
        self.searchController.dimsBackgroundDuringPresentation = false
        
        if self.hideSearchBar == false {
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: self.searchController.searchBar.bounds.height))
            headerView.addSubview(self.searchController.searchBar)
            self.tableView.tableHeaderView = headerView
        }
    }
    
    func setupSearchBarStyle() {
        if self.adjustSearchBarStyleBlock == nil {
            let searchBar = self.searchController.searchBar
            searchBar.backgroundImage = self.lr_image(with: .white)
            searchBar.barStyle = .default
            if #available(iOS 13.0, *) {
                let field = searchBar.searchTextField
                field.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
            } else {
                if let field = searchBar.value(forKey: "searchField") as? UITextField {
                    field.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
                }
            }
        } else {
            self.adjustSearchBarStyleBlock?(self.searchController.searchBar)
        }
    }
    
    func showCodeString(index: IndexPath) -> String  {
        var showCodeString: String = ""
        if self.searchController.isActive, self.isSearchStrEmpty == false {
            if self.results.count > index.row {
                showCodeString = self.results[index.row]
            }
        } else {
            if indexArray.count > index.section {
                if let sectionArray = self.sortedNameDict[self.indexArray[index.section]] {
                    if sectionArray.count > index.row {
                        showCodeString = sectionArray[index.row]
                    }
                }
            }
        }
        return showCodeString
    }
    
    func selectCode(index: IndexPath) {
        let originText = self.showCodeString(index: index)
        let array = originText.components(separatedBy: "+")
        if let name = array.first?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), let code = array.last {
            self.delegate?.lrCountry(name: name, code: code)
            self.returnCountryCodeBlock?(name, code)
        }
        self.goBack()
    }
}

extension LRCountryCodeController: LRSectionIndexViewDelegate, LRSectionIndexViewDataSource {
    func sectionIndexView(_ sectionIndexView: LRSectionIndexView, titleFor section: Int) -> String {
        return self.indexArray[section]
    }
    
    func numberOfItemViewFor(sectionIndexView: LRSectionIndexView) -> Int {
        return self.indexArray.count
    }
    func sectionIndexView(_ sectionIndexView: LRSectionIndexView, itemViewFor section: Int) -> LRSectionIndexItemView {
        let itemView = LRSectionIndexItemView()
        if section < self.indexArray.count {
            itemView.titleLabel.text = self.indexArray[section]
        } else {
            itemView.titleLabel.text = ""
        }
        itemView.titleLabel.font = UIFont.systemFont(ofSize: kIsIPad ? 15 : 12)
        if let color = self.indexViewColor {
            itemView.titleLabel.textColor = color
        } else {
            itemView.titleLabel.textColor = .black
        }
        if let color = self.highlightedIndexViewColor {
            itemView.titleLabel.highlightedTextColor = color
        } else {
            itemView.titleLabel.highlightedTextColor = UIColor(red: 21/255.0, green: 166/255.0, blue: 220/255.0, alpha: 1)
        }
        itemView.titleLabel.shadowColor = .white
        itemView.titleLabel.shadowOffset = CGSize(width: 0, height: 1)
        return itemView
    }
    func sectionIndexView(_ sectionIndexView: LRSectionIndexView, calloutViewFor section: Int) -> UIView {
        if section < self.indexArray.count {
            self.bubbleView.indexString = self.indexArray[section]
        } else {
            self.bubbleView.indexString = ""
        }
        self.bubbleView.isHidden = false
        return self.bubbleView
    }
    func sectionIndexView(_ sectionIndexView: LRSectionIndexView, didSelected section: Int) {
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: true)
    }
}

extension LRCountryCodeController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        guard let inputText = searchController.searchBar.text else { return }
        
        if inputText.isEmpty == true {
            self.isSearchStrEmpty = true
            self.refreshIndexView()
            self.tableView.reloadData()
            return;
        }
        
        self.isSearchStrEmpty = false
        self.refreshIndexView()
        self.results.removeAll()
        
        self.sortedNameDict.forEach { [weak self] (key, value) in
            let array = value.filter({ $0.contains(inputText) })
            self?.results.append(contentsOf: array)
        }
        
        self.tableView.reloadData()
    }
}

extension LRCountryCodeController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        if self.searchController.isActive, self.isSearchStrEmpty == false {
            return 1
        } else {
            return self.indexArray.count
        }
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchController.isActive, self.isSearchStrEmpty == false {
            return self.results.count
        } else {
            if self.indexArray.count > section {
                if let array = self.sortedNameDict[self.indexArray[section]] {
                    return array.count
                }
            }
            return 0
        }
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier: String = "UITableViewCellIdentifier"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: identifier)
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 14)
            cell?.detailTextLabel?.font = UIFont.systemFont(ofSize: 16)
            cell?.selectionStyle = .none
            if let color = self.rightCodeColor {
                cell?.detailTextLabel?.textColor = color
            }
        }
        
        let codeStr = self.showCodeString(index: indexPath)
        cell?.textLabel?.text = codeStr
        if self.showType == .right {
            let array = codeStr.components(separatedBy: "+")
            let name = array.first?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let code = array.last
            cell?.textLabel?.text = name
            cell?.detailTextLabel?.text = "+".appending(code ?? "")
        }
        
        if self.hideSelectImage == false, self.showType == .left {
            let isEqual = self.selectIndexStr == cell?.textLabel?.text
            cell?.accessoryView = isEqual ? self.selectImageView : nil
        }
        return cell ?? UITableViewCell()
    }
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.searchController.isActive, self.isSearchStrEmpty == false {
            return 0
        } else {
            return 30
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.indexArray.isEmpty == false, self.indexArray.count > section {
            return self.indexArray[section]
        } else {
            return ""
        }
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectCode(index: indexPath)
    }
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchController.searchBar.resignFirstResponder()
    }
}

extension LRCountryCodeController {
    func lr_countryCodeBundle() -> Bundle? {
        let bundle = Bundle(for: type(of: self))
        return Bundle(path: bundle.path(forResource: "LRCountryCode", ofType: "bundle") ?? "")
    }
    func lr_image(with color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        guard size.width * size.height > 0, size.width > 0 else { return nil }
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
