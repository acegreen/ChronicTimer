//
//  ExpandingCell.swift
//  ExpandingStackCells
//
//  Created by József Vesza on 27/06/15.
//  Copyright © 2015 Jozsef Vesza. All rights reserved.
//

import UIKit

class ExpandingCell: UITableViewCell {
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var detail: String? {
        didSet {
            detailLabel.text = detail
        }
    }
    
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        stackView.arrangedSubviews.last?.isHidden = true
    }
    
    func changeCellStatus(_ selected: Bool){
        UIView.animate(withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 1,
            options: UIViewAnimationOptions.curveEaseIn,
            animations: { () -> Void in
                self.stackView.arrangedSubviews.last?.isHidden = !selected
            },
            completion: nil)
    }
}
