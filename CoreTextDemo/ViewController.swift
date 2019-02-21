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
			let quote = "中｜中，中。中、中？中！中：中……"
			let baseStyle = StringStyle(.font(UIFont(name: "PingFangHK-Light", size: 20)!),
										.color(BONColor.red),
									.lineSpacing(5),
									.lineBreakMode(.byCharWrapping),
									.alignment(.natural))
			let quoteStyle = baseStyle.byAdding(.tracking(.point(20)))
			
			let str = quote.styled(with: quoteStyle)
			let mStr = NSMutableAttributedString.init(attributedString: str)
			mStr.addAttribute(.kern, value: 0, range: NSMakeRange(0, str.length))
			return mStr
		}
		textLabel.vertical = true
		textLabel.numberOfLines = 5
		textLabel.backgroundColor = UIColor.white
		textLabel.contentInset = UIEdgeInsets(top: 50, left: 10, bottom: 50, right: 10)

		view.addSubview(textLabel)
		textLabel.snp.makeConstraints { maker in
			maker.edges.equalToSuperview()
		}
		
		view.backgroundColor = UIColor.white
	}


}

