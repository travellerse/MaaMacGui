//
//  CopilotConfiguration.swift
//  MAA
//
//  Created by hguandl on 17/4/2023.
//

import Foundation

struct RegularCopilotConfiguration: Codable {
    var enable = true
    var filename: String
    var formation = false
    var support_unit_usage = 0
    var support_unit_name = ""
    var add_trust = false
    var ignore_requirements = false
    var user_additional = [UserAdditional]()
    var formation_index = 0
    var loop_times = 1
    var use_sanity_potion = false

    struct UserAdditional: Codable, Equatable {
        var name: String
        var skill = 0
        var module = 0
    }
}

struct SSSCopilotConfiguration: Codable {
    var enable = true
    var filename: String
    var loop_times = 1
}

struct VideoRecognitionConfiguration: Codable {
    var enable = true
    var filename: String

    var params: String? {
        try? jsonString()
    }
}

enum CopilotConfiguration {
    case regular(RegularCopilotConfiguration)
    case sss(SSSCopilotConfiguration)

    var params: String? {
        switch self {
        case .regular(let config):
            return try? config.jsonString()
        case .sss(let config):
            return try? config.jsonString()
        }
    }
}
