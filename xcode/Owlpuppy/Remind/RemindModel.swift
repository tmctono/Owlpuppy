//
//  EventKitRemindModel.swift
//  Owlpuppy
//
//  Created by Manabu Tonosaki on 2026-03-05.
//

import Foundation

class RemindItem: Codable {
    let isoDateTime: Date
    let message: String
}

class RemindModel: ModelProtocol {
    let items: [RemindItem]
}
