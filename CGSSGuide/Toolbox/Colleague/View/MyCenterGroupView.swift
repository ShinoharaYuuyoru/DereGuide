//
//  ProfileMemberEditableView.swift
//  CGSSGuide
//
//  Created by zzk on 2017/8/3.
//  Copyright © 2017年 zzk. All rights reserved.
//

import UIKit

protocol MyCenterGroupViewDelegate: class {
    func profileMemberEditableView(_ profileMemberEditableView: MyCenterGroupView, didLongPressAt item: MyCenterItemView)
    func profileMemberEditableView(_ profileMemberEditableView: MyCenterGroupView, didDoubleTap item: MyCenterItemView)
}

class MyCenterGroupView: UIView {
    
    weak var delegate: MyCenterGroupViewDelegate?
    
    var descLabel: UILabel!
    
    var stackView: UIStackView!
    
    var editableItemViews: [MyCenterItemView]!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let types = [CGSSLiveTypes.cute, .cool, .passion, .allType]
        editableItemViews = [MyCenterItemView]()
        for index in 0..<4 {
            let view = MyCenterItemView()
            view.setup(with: types[index])
            editableItemViews.append(view)
            view.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture(_:)))
            doubleTap.numberOfTapsRequired = 2
            
            view.addGestureRecognizer(doubleTap)
            view.addGestureRecognizer(tap)
            view.addGestureRecognizer(longPress)
        }
        stackView = UIStackView(arrangedSubviews: editableItemViews)
        stackView.spacing = 6
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        addSubview(stackView)
        
        stackView.snp.remakeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.greaterThanOrEqualTo(10)
            make.right.lessThanOrEqualTo(-10)
            // make the view as wide as possible
            make.right.equalTo(-10).priority(900)
            make.left.equalTo(10).priority(900)
            //
            make.bottom.equalToSuperview()
            make.width.lessThanOrEqualTo(104 * 5 + 30)
            make.centerX.equalToSuperview()
        }
        
    }
    
    @objc func handleTapGesture(_ tap: UITapGestureRecognizer) {
//        if let view = tap.view as? TeamMemberEditableItemView {
//            if let index = stackView.arrangedSubviews.index(of: view) {
//                // select index
//            }
//        }
    }
    
    @objc func handleLongPressGesture(_ longPress: UILongPressGestureRecognizer) {
        if longPress.state == .began {
            guard let view = longPress.view as? MyCenterItemView else { return }
            delegate?.profileMemberEditableView(self, didLongPressAt: view)
        }
    }
    
    @objc func handleDoubleTapGesture(_ doubleTap: UITapGestureRecognizer) {
        guard let view = doubleTap.view as? MyCenterItemView else { return }
        delegate?.profileMemberEditableView(self, didDoubleTap: view)
    }
    
    func setupWith(cardID: Int, potential: CGSSPotential, at index: Int) {
        editableItemViews[index].setupWith(cardID: cardID, potential: potential)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
