//
//  ViewController.swift
//  LRCountryCode
//
//  Created by huawentao on 08/22/2022.
//  Copyright (c) 2022 huawentao. All rights reserved.
//

import UIKit
import LRCountryCode

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        button.backgroundColor = .red
        button.center = self.view.center
        self.view.addSubview(button)
        button.addTarget(self, action: #selector(test), for: .touchUpInside)
    }

    @objc func test() {
        let country = LRCountryCodeController(with: "86")
        country.modalPresentationStyle = .overCurrentContext
        self.present(country, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

