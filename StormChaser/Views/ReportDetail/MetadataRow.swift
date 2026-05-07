import SwiftUI

struct MetadataRow: View {
    let symbol: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
