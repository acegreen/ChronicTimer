//
//  ExcerciseTableViewCell.swift
//  Chronic
//
//  Created by Ace Green on 2015-07-25.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit

class ExerciseTableViewCell: UITableViewCell {
    
    @IBOutlet var excerciseNameTextField: UITextField!
    @IBOutlet var exerciseTimeTextField: TimePickerTextField!
    @IBOutlet var exerciseNumberOfRounds: NumberPickerTextField!
    @IBOutlet var exerciseColorTextField: ColorPickerTextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
