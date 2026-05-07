import SwiftUI

struct ReportRow: View {
    let report: StormReport

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: report.stormType.symbolName)
                        .foregroundStyle(.tint)
                    Text(report.stormType.displayName)
                        .font(.body.weight(.semibold))
                    Spacer(minLength: 0)
                    SyncBadge(status: report.syncStatus)
                }
                Text(report.createdAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !report.notes.isEmpty {
                    Text(report.notes)
                        .font(.footnote)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let filename = report.imageFilename, let image = ImageStore.shared.loadImage(named: filename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                Image(systemName: report.stormType.symbolName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 56, height: 56)
        }
    }
}
