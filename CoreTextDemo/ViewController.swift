//
//  ViewController.swift
//  CoreTextDemo
//
//  Created by guoyiyuan on 2018/11/27.
//  Copyright © 2018 guoyiyuan. All rights reserved.
//

import UIKit
import SnapKit
import BonMot

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		let textLabel: CTTextLabel = CTTextLabel()
		textLabel.textCb = {
			let quote = "『这是希望之春，这是失望之冬』"
			let baseStyle = StringStyle(.font(UIFont(name: "beifang", size: 20) ?? UIFont(name: "MMXHN", size: 20) ?? UIFont.systemFont(ofSize: 20)),
									.lineSpacing(5),
									.lineBreakMode(.byCharWrapping),
									.alignment(.natural))
			let quoteStyle = baseStyle.byAdding(.tracking(.point(20)))
			
			let str = quote.styled(with: quoteStyle)
			let mStr = NSMutableAttributedString.init(attributedString: str)
			mStr.addAttribute(.kern, value: 15, range: NSMakeRange(0, str.length))
			return mStr
		}
		textLabel.vertical = true
		textLabel.numberOfLines = 3
		textLabel.backgroundColor = UIColor.white
		textLabel.contentInset = UIEdgeInsets(top: 50, left: 10, bottom: 50, right: 10)

		view.addSubview(textLabel)
		textLabel.snp.makeConstraints { maker in
			maker.edges.equalToSuperview()
		}
		
		view.backgroundColor = UIColor.white
	}


}

