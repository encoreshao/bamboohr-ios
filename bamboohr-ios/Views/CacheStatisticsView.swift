//
//  CacheStatisticsView.swift
//  bamboohr-ios
//
//  Created on 2025/9/7.
//

import SwiftUI

struct CacheStatisticsView: View {
    @ObservedObject private var cacheManager = DataCacheManager.shared

    var body: some View {
        NavigationView {
            List {
                Section("Cache Performance") {
                    StatRow(label: "Total Requests", value: "\(cacheManager.totalRequests)")
                    StatRow(label: "Cache Hits", value: "\(cacheManager.cacheHits)")
                    StatRow(label: "Cache Misses", value: "\(cacheManager.cacheMisses)")
                    StatRow(label: "Hit Rate", value: String(format: "%.1f%%", cacheManager.cacheHitRate))
                }

                Section("Cache Management") {
                    Button(action: {
                        cacheManager.clearExpiredCaches()
                        HapticFeedback.light()
                    }) {
                        HStack {
                            Image(systemName: "trash.circle")
                                .foregroundColor(.orange)
                            Text("Clear Expired Caches")
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
                            Text("Clear All Caches")
                                .foregroundColor(.red)
                        }
                    }
                }

                Section("Cache Benefits") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caching reduces:")
                            .font(.headline)

                        BenefitRow(icon: "network", text: "API calls and network usage")
                        BenefitRow(icon: "speedometer", text: "App loading times")
                        BenefitRow(icon: "battery.100", text: "Battery consumption")
                        BenefitRow(icon: "doc.text", text: "Log output volume")
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Cache Statistics")
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
