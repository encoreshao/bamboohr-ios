//
//  CacheStatisticsView.swift
//  bamboohr-ios
//
//  Created on 2025/9/7.
//

import SwiftUI

struct CacheStatisticsView: View {
    @ObservedObject private var cacheManager = DataCacheManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        NavigationView {
            List {
                Section(localizationManager.localized(.cachePerformance)) {
                    StatRow(label: localizationManager.localized(.cacheTotalRequests), value: "\(cacheManager.totalRequests)")
                    StatRow(label: localizationManager.localized(.cacheCacheHits), value: "\(cacheManager.cacheHits)")
                    StatRow(label: localizationManager.localized(.cacheCacheMisses), value: "\(cacheManager.cacheMisses)")
                    StatRow(label: localizationManager.localized(.cacheHitRate), value: String(format: "%.1f%%", cacheManager.cacheHitRate))
                }

                Section(localizationManager.localized(.cacheManagement)) {
                    Button(action: {
                        cacheManager.clearExpiredCaches()
                        HapticFeedback.light()
                    }) {
                        HStack {
                            Image(systemName: "trash.circle")
                                .foregroundColor(.orange)
                            Text(localizationManager.localized(.cacheClearExpired))
                                .foregroundColor(.primary)
                        }
                    }

                    Button(action: {
                        cacheManager.clearCache()
                        HapticFeedback.medium()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text(localizationManager.localized(.cacheClearAll))
                                .foregroundColor(.red)
                        }
                    }
                }

                Section(localizationManager.localized(.cacheBenefits)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.localized(.cachingReduces))
                            .font(.headline)

                        BenefitRow(icon: "network", text: localizationManager.localized(.cacheApiCalls))
                        BenefitRow(icon: "speedometer", text: localizationManager.localized(.cacheLoadingTimes))
                        BenefitRow(icon: "battery.100", text: localizationManager.localized(.cacheBatteryConsumption))
                        BenefitRow(icon: "doc.text", text: localizationManager.localized(.cacheLogOutput))
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(localizationManager.localized(.cacheStatistics))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// HapticFeedback is already defined in MicroInteractions.swift

#Preview {
    CacheStatisticsView()
}
