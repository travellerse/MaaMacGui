//
//  MAACopilot.swift
//  MAA
//
//  Created by hguandl on 17/4/2023.
//

import Foundation

struct MAACopilot: Codable, Equatable {
    let stage_name: String
    let opers: [Operator]
    let groups: [Group]?
    let minimum_required: String
    let doc: Documentation?

    // MARK: SSS

    let type: String?
    let equipment: [String]?
    let strategy: String?
    let tool_men: [String: Int]?

    struct Operator: Codable, Equatable {
        let name: String
        let skill: Int?
        let requirements: Requirements?

        struct Requirements: Codable, Equatable {
            let elite: Int?
            let level: Int?
            let skill_level: Int?
            let module: Int?
        }
    }

    struct Group: Codable, Equatable {
        let name: String
        let opers: [Operator]
    }

    struct Documentation: Codable, Equatable {
        let title: String?
        let title_color: String?
        let details: String?
        let details_color: String?
    }
}

extension MAACopilot.Operator: CustomStringConvertible {
    var description: String {
        var segments: [String] = [name]

        if let skill {
            segments.append("技能 \(skill)")
        }

        if let requirements {
            if let module = requirements.module, module >= 0 {
                let moduleSymbol = ["", "χ", "γ", "α", "Δ"]
                if module == 0 {
                    segments.append("[无模组]")
                } else if module < moduleSymbol.count {
                    segments.append("[模组 \(moduleSymbol[module])]")
                }
            }
        }

        return segments.joined(separator: " ")
    }
}

extension MAACopilot {
    init?(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            self = try JSONDecoder().decode(MAACopilot.self, from: data)
        } catch {
            return nil
        }
    }
}
