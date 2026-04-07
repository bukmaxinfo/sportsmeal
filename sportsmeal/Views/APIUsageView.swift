import SwiftUI

struct APIUsageView: View {
    @State private var usage: APIUsageSummary?

    var body: some View {
        List {
            Section("Session Usage") {
                if let usage = usage {
                    LabeledContent("Total Requests", value: "\(usage.totalRequests)")
                    LabeledContent("Vision (Photo) Requests", value: "\(usage.visionRequests)")
                    LabeledContent("Text Requests", value: "\(usage.textRequests)")
                    LabeledContent("Est. Tokens Used", value: "\(usage.estimatedTokens)")
                } else {
                    Text("Loading...")
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }

            Section("Cost Estimate") {
                if let usage = usage {
                    let inputCost = Double(usage.estimatedTokens) * 0.000003 // ~$3/1M input tokens
                    let outputCost = Double(usage.estimatedTokens) * 0.000015 * 0.3 // ~$15/1M output, ~30% are output
                    let total = inputCost + outputCost
                    LabeledContent("Est. Session Cost", value: String(format: "$%.4f", total))
                        .foregroundStyle(AppTheme.gold)
                }

                Text("Based on Claude Sonnet pricing. Actual costs may vary.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Section("Optimization") {
                HStack {
                    Label("Response Cache", systemImage: "memorychip")
                    Spacer()
                    Text("5 min TTL")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                HStack {
                    Label("Image Compression", systemImage: "photo")
                    Spacer()
                    Text("60% quality, max 1024px")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Button {
                    Task {
                        await ClaudeAPIClient.shared.clearCache()
                    }
                } label: {
                    Label("Clear Cache", systemImage: "trash")
                        .foregroundStyle(AppTheme.negative)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("API Usage")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            usage = await ClaudeAPIClient.shared.usageSummary
        }
    }
}
