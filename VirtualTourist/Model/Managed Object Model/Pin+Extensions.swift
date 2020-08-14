//
//  Pin+Extenision.swift
//  VirtualTourist
//
//  Created by Riham Mastour on 22/12/1441 AH.
//  Copyright © 1441 Riham Mastour. All rights reserved.
//

import Foundation
import CoreData

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
