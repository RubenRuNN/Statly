//
//  StatSelectionView.swift
//  Statly
//
//  Created by Ruben Marques on 25/01/2026.
//

import SwiftUI

struct StatSelectionView: View {
    let availableStats: [Stat]
    @Binding var selectedIndices: [Int]
    
    var body: some View {
        VStack(spacing: 0) {
            if availableStats.isEmpty {
                emptyStateView
            } else {
                statsList
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.title2)
                .foregroundStyle(.secondary.opacity(0.5))
            Text("No stats available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Test your endpoint connection to see available stats")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
    }
    
    private var statsList: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(selectedIndices.count) of \(availableStats.count) selected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !selectedIndices.isEmpty {
                        Text("Long press selected stats to reorder")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                if !selectedIndices.isEmpty {
                    Button(action: clearSelection) {
                        Text("Clear All")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // Selected stats section
            if !selectedIndices.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Stats")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 4)
                    
                    List {
                        ForEach(Array(selectedIndices.enumerated()), id: \.element) { orderIndex, statIndex in
                            if statIndex < availableStats.count {
                                StatSelectionRow(
                                    stat: availableStats[statIndex],
                                    index: statIndex,
                                    isSelected: true,
                                    position: orderIndex,
                                    totalSelected: selectedIndices.count,
                                    onToggle: { toggleStat(at: statIndex) }
                                )
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                            }
                        }
                        .onMove { source, destination in
                            selectedIndices.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                    .environment(\.editMode, .constant(.active))
                    .listStyle(.plain)
                    .frame(height: min(CGFloat(selectedIndices.count) * 70, 350))
                    .scrollContentBackground(.hidden)
                }
            }
            
            // Available stats section
            let unselectedIndices = availableStats.indices.filter { !selectedIndices.contains($0) }
            if !unselectedIndices.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedIndices.isEmpty ? "Available Stats" : "Add More Stats")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(unselectedIndices.enumerated()), id: \.element) { _, statIndex in
                            StatSelectionRow(
                                stat: availableStats[statIndex],
                                index: statIndex,
                                isSelected: false,
                                position: nil,
                                totalSelected: selectedIndices.count,
                                onToggle: { toggleStat(at: statIndex) }
                            )
                            
                            if statIndex != unselectedIndices.last {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private func toggleStat(at index: Int) {
        if let position = selectedIndices.firstIndex(of: index) {
            selectedIndices.remove(at: position)
        } else {
            selectedIndices.append(index)
        }
    }
    
    private func clearSelection() {
        selectedIndices.removeAll()
    }
}

struct StatSelectionRow: View {
    let stat: Stat
    let index: Int
    let isSelected: Bool
    let position: Int?
    let totalSelected: Int
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Stat info
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Text(stat.value)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let trend = stat.trend {
                        HStack(spacing: 2) {
                            if let direction = stat.trendDirection {
                                Text(direction.icon)
                                    .font(.caption2)
                                Text(trend)
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(trendColor(for: stat.trendDirection))
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private func trendColor(for direction: TrendDirection?) -> Color {
        guard let direction = direction else { return .secondary }
        switch direction {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
}


#Preview {
    let sampleStats = [
        Stat(label: "USERS", value: "1,234", trend: "+12%", trendDirection: .up),
        Stat(label: "MRR", value: "$45.2K", trend: "-5%", trendDirection: .down),
        Stat(label: "CONVERSIONS", value: "89", trend: "0%", trendDirection: .neutral),
        Stat(label: "REVENUE", value: "$12.5K", trend: "+15%", trendDirection: .up),
        Stat(label: "CHURN", value: "2.3%", trend: "-1%", trendDirection: .down)
    ]
    
    return NavigationView {
        Form {
            Section {
                StatSelectionView(
                    availableStats: sampleStats,
                    selectedIndices: .constant([0, 2, 3])
                )
            } header: {
                Text("Select Stats")
            }
        }
    }
}
