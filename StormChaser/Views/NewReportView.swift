import SwiftUI
import SwiftData
import UIKit

struct NewReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.syncCoordinator) private var syncCoordinator

    @State private var viewModel: NewReportViewModel
    @State private var presentedPickerSource: PresentedPickerSource?

    private struct PresentedPickerSource: Identifiable {
        let source: ImagePickerSource
        var id: String { source == .camera ? "camera" : "library" }
    }

    init(viewModel: NewReportViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    NewReportPhotoSection(
                        capturedImage: viewModel.capturedImage,
                        onCamera: { presentedPickerSource = PresentedPickerSource(source: .camera) },
                        onLibrary: { presentedPickerSource = PresentedPickerSource(source: .library) }
                    )
                }

                Section("Storm classification") {
                    Picker("Type", selection: $viewModel.stormType) {
                        ForEach(StormType.allCases) { type in
                            Label(type.displayName, systemImage: type.symbolName).tag(type)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Description, observations, intensity...", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Conditions") {
                    NewReportConditionsSection(
                        isFetchingMeta: viewModel.isFetchingMeta,
                        coordinate: viewModel.coordinate,
                        weather: viewModel.weather,
                        metaError: viewModel.metaError,
                        onFetch: { Task { await viewModel.fetchMetadata() } }
                    )
                }
            }
            .navigationTitle("New Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: handleSave)
                        .disabled(!viewModel.canSave)
                }
            }
            .sheet(item: $presentedPickerSource) { presented in
                ImagePicker(source: presented.source) { image in
                    viewModel.capturedImage = image
                    if viewModel.coordinate == nil {
                        Task { await viewModel.fetchMetadata() }
                    }
                }
                .ignoresSafeArea()
            }
        }
    }

    private func handleSave() {
        guard viewModel.save() != nil else { return }
        syncCoordinator?.nudge()
        dismiss()
    }
}
