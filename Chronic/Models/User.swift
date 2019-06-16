//
//  User.swift
//  Chronic
//
//  Created by Ace Green on 6/15/19.
//  Copyright © 2019 Ace Green. All rights reserved.
//

import Foundation
import Parse

public class User: PFUser {
    
    @NSManaged var proVersionPurchased: Bool
    @NSManaged var removeAdsPurchased: Bool
    @NSManaged var emailVerified: Bool
}
