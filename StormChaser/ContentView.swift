import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.weatherService) private var weatherService
    @Environment(\.locationService) private var locationService
    @Environment(\.modelContext) private var modelContext

    @State private var weatherViewModel: WeatherViewModel?

    var body: some View {
        TabView {
            Group {
                if let weatherViewModel {
                    WeatherView(viewModel: weatherViewModel)
                } else {
                    ProgressView()
                }
            }
            .tabItem { Label("Weather", systemImage: "cloud.sun") }

            ReportsListView()
                .tabItem { Label("Reports", systemImage: "tray.full") }

            StormMapView()
                .tabItem { Label("Map", systemImage: "map") }
        }
        .onAppear {
            if weatherViewModel == nil {
                weatherViewModel = WeatherViewModel(
                    weatherService: weatherService,
                    locationService: locationService,
                    modelContext: modelContext
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StormReport.self, CachedWeather.self], inMemory: true)
}
