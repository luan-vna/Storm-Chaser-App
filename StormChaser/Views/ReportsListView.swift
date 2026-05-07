import SwiftUI
import SwiftData

struct ReportsListView: View {
    @Query(sort: \StormReport.createdAt, order: .reverse) private var reports: [StormReport]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.weatherService) private var weatherService
    @Environment(\.locationService) private var locationService
    @Environment(\.syncCoordinator) private var syncCoordinator
    @Environment(\.networkMonitor) private var networkMonitor

    @State private var showingNewReport = false

    var body: some View {
        NavigationStack {
            Group {
                if reports.isEmpty {
                    NotFoundView(
                        title: "No storm reports yet",
                        message: "Tap the + button to document your first storm with a photo, location, and conditions.",
                        symbolName: "tray"
                    )
                } else {
                    List {
                        if !networkMonitor.isConnected {
                            Section {
                                OfflineRow()
                            }
                            .listRowBackground(Color.orange.opacity(0.12))
                        }
                        Section {
                            ForEach(reports) { report in
                                NavigationLink {
                                    ReportDetailView(report: report)
                                } label: {
                                    ReportRow(report: report)
                                }
                            }
                            .onDelete(perform: deleteReports)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        syncCoordinator?.nudge()
                        try? await Task.sleep(nanoseconds: 300_000_000)
                    }
                }
            }
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SyncIndicator()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewReport = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showingNewReport) {
                NewReportView(viewModel: NewReportViewModel(
                    weatherService: weatherService,
                    locationService: locationService,
                    modelContext: modelContext
                ))
            }
        }
    }

    private func deleteReports(at offsets: IndexSet) {
        for index in offsets {
            let report = reports[index]
            if let filename = report.imageFilename {
                ImageStore.shared.delete(filename: filename)
            }
            modelContext.delete(report)
        }
    }
}
