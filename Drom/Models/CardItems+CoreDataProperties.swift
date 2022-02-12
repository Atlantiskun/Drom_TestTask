//
//  CardItems+CoreDataProperties.swift
//  Drom
//
//  Created by Дмитрий Болучевских on 11.02.2022.
//
//

import Foundation
import CoreData


extension CardItems {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CardItems> {
        return NSFetchRequest<CardItems>(entityName: "CardItems")
    }

    @NSManaged public var stringUrl: String
    @NSManaged public var image: Data?

}
