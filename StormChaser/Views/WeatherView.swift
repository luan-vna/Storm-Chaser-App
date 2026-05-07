import SwiftUI
import SwiftData

struct WeatherView: View {
    @State private var viewModel: WeatherViewModel

    init(viewModel: WeatherViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Conditions")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await viewModel.refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .task { await viewModel.loadIfNeeded() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ScrollView {
                WeatherSkeletonView()
                    .padding(.top)
            }
        case .loaded(let report, let fetchedAt, let isStale):
            ScrollView {
                if isStale {
                    OfflineBanner(fetchedAt: fetchedAt)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                LoadedWeatherView(report: report)
            }
            .refreshable { await viewModel.refresh() }
        case .notFound(let message):
            NotFoundView(
                title: "Weather not found",
                message: message,
                retry: { Task { await viewModel.refresh() } }
            )
        }
    }
}
