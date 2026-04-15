//
//  CopilotView.swift
//  MAA
//
//  Created by hguandl on 19/4/2023.
//

import SwiftUI

struct CopilotView: View {
    @EnvironmentObject private var viewModel: MAAViewModel
    let url: URL

    var body: some View {
        if let copilot = MAACopilot(url: url) {
            VStack(spacing: 20) {
                pilotConfiguration()

                Divider()

                ScrollView {
                    pilotDescription(pilot: copilot)
                }
            }
            .task(id: url) { updateCopilot() }
        } else {
            Text("文件格式错误")
        }
    }

    private func updateCopilot() {
        guard let copilot = MAACopilot(url: url) else { return }
        if copilot.type == "SSS" {
            viewModel.copilot = .sss(.init(filename: url.path))
        } else {
            viewModel.copilot = .regular(.init(filename: url.path))
        }
    }

    private var copilot: MAACopilot? {
        MAACopilot(url: url)
    }

    // MARK: - Copilot Config

    @ViewBuilder private func pilotConfiguration() -> some View {
        switch viewModel.copilot {
        case .regular(let innerConfig):
            RegularPilotConfigurationView(
                config: Binding(get: { innerConfig }, set: { viewModel.copilot = .regular($0) })
            )
        case .sss(let innerConfig):
            SSSCopilotConfigurationView(
                config: Binding(get: { innerConfig }, set: { viewModel.copilot = .sss($0) })
            )
        case .none:
            EmptyView()
        }
    }

    // MARK: - Regular Pilot Configuration

    private struct RegularPilotConfigurationView: View {
        @Binding var config: RegularCopilotConfiguration

        @State private var showUserAdditionalEditor = false
        @State private var editingUserAdditionals: [RegularCopilotConfiguration.UserAdditional] = []

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                formationSection
                executionSection
            }
            .sheet(isPresented: $showUserAdditionalEditor) {
                userAdditionalEditor
            }
        }

        // MARK: Formation Section

        @ViewBuilder
        private var formationSection: some View {
            Toggle("自动编队", isOn: $config.formation)

            if config.formation {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("信赖干员", isOn: $config.add_trust)
                    Toggle("忽略干员属性要求", isOn: $config.ignore_requirements)

                    HStack {
                        Picker("编队序号", selection: $config.formation_index) {
                            Text("当前编队").tag(0)
                            Text("编队1").tag(1)
                            Text("编队2").tag(2)
                            Text("编队3").tag(3)
                            Text("编队4").tag(4)
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Picker("助战使用", selection: $config.support_unit_usage) {
                            Text("不使用").tag(0)
                            Text("仅缺一人时补助战").tag(1)
                            Text("指定助战干员").tag(2)
                            Text("随机助战").tag(3)
                        }
                        .pickerStyle(.menu)

                        if config.support_unit_usage == 2 {
                            TextField("助战干员名称", text: $config.support_unit_name)
                                .frame(maxWidth: 160)
                        }
                    }

                    HStack {
                        Text("自定干员 (\(config.user_additional.count))")
                        Button("编辑") {
                            editingUserAdditionals = config.user_additional
                            showUserAdditionalEditor = true
                        }
                    }
                }
                .padding(.leading, 20)
            }
        }

        // MARK: Execution Section

        private var executionSection: some View {
            Group {
                Divider()
                Stepper("重复次数: \(config.loop_times)",
                        value: $config.loop_times,
                        in: 1 ... 9999)
                Toggle("使用理智药", isOn: $config.use_sanity_potion)
            }
        }

        // MARK: User Additional Editor

        private var userAdditionalEditor: some View {
            NavigationStack {
                List {
                    ForEach(editingUserAdditionals.indices, id: \.self) { index in
                        HStack {
                            TextField("干员名", text: $editingUserAdditionals[index].name)
                                .frame(minWidth: 100)
                            Picker("技能", selection: $editingUserAdditionals[index].skill) {
                                Text("自动").tag(0)
                                Text("技能1").tag(1)
                                Text("技能2").tag(2)
                                Text("技能3").tag(3)
                            }
                            .frame(maxWidth: 100)
                            Button {
                                editingUserAdditionals.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Button("添加干员") {
                        editingUserAdditionals.append(.init(name: ""))
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { showUserAdditionalEditor = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            config.user_additional = editingUserAdditionals.filter {
                                !$0.name.trimmingCharacters(in: .whitespaces).isEmpty
                            }
                            showUserAdditionalEditor = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - SSS Copilot Configuration

    private struct SSSCopilotConfigurationView: View {
        @Binding var config: SSSCopilotConfiguration

        var body: some View {
            HStack {
                Text("循环次数")
                TextField("1", value: $config.loop_times, format: .number)
            }
            .frame(maxWidth: 130)
        }
    }

    // MARK: - Copilot Document

    @ViewBuilder private func pilotDescription(pilot: MAACopilot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = pilot.doc?.title {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            if let details = pilot.doc?.details {
                Text(details)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            if let equipments = pilot.equipment {
                HStack {
                    Text("装备：")
                        .fontWeight(.semibold)
                    Text(equipments.joined(separator: ", "))
                }
                .font(.subheadline)
            }

            if let strategy = pilot.strategy {
                Text(strategy)
                    .font(.subheadline)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }

            if pilot.opers.count > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("干员配置")
                        .font(.headline)

                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                        ForEach(pilot.opers, id: \.name) { oper in
                            GridRow {
                                Text(oper.name)
                                    .fontWeight(.medium)
                                    .gridColumnAlignment(.trailing)

                                if let requirements = oper.requirements, let elite = requirements.elite, let level = requirements.level, elite > 0 || level > 0 {
                                    tagView(text: "精\(elite) Lv.\(level)", color: .orange)
                                } else {
                                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                }

                                if let skill = oper.skill {
                                    tagView(text: "技能 \(skill)", color: .blue)
                                } else {
                                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                }

                                if let requirements = oper.requirements, let skillLevel = requirements.skill_level, skillLevel > 0 {
                                    if skillLevel <= 7 {
                                        tagView(text: "Lv.\(skillLevel)", color: .blue.opacity(0.8))
                                    } else {
                                        tagView(text: "专精 \(skillLevel - 7)", color: .blue.opacity(0.8))
                                    }
                                } else {
                                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                }

                                if let requirements = oper.requirements, let module = requirements.module, module >= 0 {
                                    let moduleSymbol = ["无", "χ", "γ", "α", "Δ"]
                                    if module < moduleSymbol.count {
                                        tagView(text: "模组 \(moduleSymbol[module])", color: .purple)
                                    } else {
                                        Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                    }
                                } else {
                                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                }
                            }
                        }
                    }
                }
            }

            if let groups = pilot.groups {
                VStack(alignment: .leading, spacing: 12) {
                    Text("干员分组")
                        .font(.headline)

                    ForEach(groups, id: \.name) { group in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(group.opers, id: \.name) { oper in
                                    operatorRow(oper: oper)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }

            if let toolmen = pilot.tool_men {
                HStack {
                    Text("工具人：")
                        .fontWeight(.semibold)
                    Text(toolmen.sorted { $0.key < $1.key }.map { "\($1)\($0)" }.joined(separator: ", "))
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder private func operatorRow(oper: MAACopilot.Operator) -> some View {
        HStack(spacing: 8) {
            Text(oper.name)
                .fontWeight(.medium)

            if let requirements = oper.requirements, let elite = requirements.elite, let level = requirements.level, elite > 0 || level > 0 {
                tagView(text: "精\(elite) Lv.\(level)", color: .orange)
            }

            if let skill = oper.skill {
                tagView(text: "技能 \(skill)", color: .blue)
            }

            if let requirements = oper.requirements, let skillLevel = requirements.skill_level, skillLevel > 0 {
                tagView(text: "Lv.\(skillLevel)", color: .blue.opacity(0.8))
            }

            if let requirements = oper.requirements, let module = requirements.module, module >= 0 {
                let moduleSymbol = ["无", "χ", "γ", "α", "Δ"]
                if module < moduleSymbol.count {
                    tagView(text: "模组 \(moduleSymbol[module])", color: .purple)
                }
            }
        }
    }

    private func tagView(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// A simple flow layout for groups
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += maxHeight + spacing
                maxHeight = 0
            }
            maxHeight = max(maxHeight, size.height)
            currentX += size.width + spacing
        }
        height = currentY + maxHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += maxHeight + spacing
                maxHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            maxHeight = max(maxHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

// MARK: - Previews

struct CopilotView_Previews: PreviewProvider {
    static let url = Bundle.main.resourceURL!
        .appendingPathComponent("resource")
        .appendingPathComponent("copilot")
        .appendingPathComponent("SSS_约翰老妈新建地块")
        .appendingPathExtension("json")

    static var previews: some View {
        VStack {
            CopilotView(url: url)
        }
        .environmentObject(MAAViewModel())
    }
}
