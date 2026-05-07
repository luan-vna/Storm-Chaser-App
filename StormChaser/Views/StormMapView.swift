import SwiftUI
import SwiftData
import MapKit

struct StormMapView: View {
    @Query(sort: \StormReport.createdAt, order: .reverse) private var reports: [StormReport]
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedReportID: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if reports.isEmpty {
                    NotFoundView(
                        title: "Nothing to map yet",
                        message: "Storm reports you save will appear here as pins.",
                        symbolName: "mappin.slash"
                    )
                } else {
                    Map(position: $cameraPosition, selection: $selectedReportID) {
                        ForEach(reports) { report in
                            Marker(
                                report.stormType.displayName,
                                systemImage: report.stormType.symbolName,
                                coordinate: CLLocationCoordinate2D(latitude: report.latitude, longitude: report.longitude)
                            )
                            .tint(color(for: report.stormType))
                            .tag(report.id)
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .safeAreaInset(edge: .bottom) {
                        if let id = selectedReportID, let report = reports.first(where: { $0.id == id }) {
                            selectedCard(for: report)
                                .padding()
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut, value: selectedReportID)
                    .onAppear { fitToReports() }
                }
            }
            .navigationTitle("Storm Map")
            .toolbar {
                if !reports.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            fitToReports()
                        } label: {
                            Image(systemName: "scope")
                        }
                    }
                }
            }
        }
    }

    private func selectedCard(for report: StormReport) -> some View {
        NavigationLink {
            ReportDetailView(report: report)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: report.stormType.symbolName)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(color(for: report.stormType), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(report.stormType.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(report.createdAt, format: .dateTime.month().day().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !report.notes.isEmpty {
                        Text(report.notes)
                            .font(.footnote)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func fitToReports() {
        guard !reports.isEmpty else { return }
        let lats = reports.map(\.latitude)
        let lons = reports.map(\.longitude)
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.05, (maxLat - minLat) * 1.5),
            longitudeDelta: max(0.05, (maxLon - minLon) * 1.5)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    private func color(for type: StormType) -> Color {
        switch type {
        case .tornado, .hurricane, .derecho: return .red
        case .thunderstorm, .hailstorm: return .orange
        case .blizzard, .waterspout: return .blue
        case .duststorm: return .brown
        case .other: return .gray
        }
    }
}
