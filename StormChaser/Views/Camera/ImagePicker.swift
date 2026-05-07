import SwiftUI
import UIKit
import PhotosUI

enum ImagePickerSource {
    case camera
    case library
}

struct ImagePicker: View {
    let source: ImagePickerSource
    let onPicked: (UIImage) -> Void

    var body: some View {
        switch source {
        case .camera:
            CameraPicker(onPicked: onPicked)
                .ignoresSafeArea()
        case .library:
            PhotoLibraryPicker(onPicked: onPicked)
                .ignoresSafeArea()
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    let onPicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked, dismiss: { dismiss() })
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPicked: (UIImage) -> Void
        let dismiss: () -> Void

        init(onPicked: @escaping (UIImage) -> Void, dismiss: @escaping () -> Void) {
            self.onPicked = onPicked
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onPicked(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

private struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let onPicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked, dismiss: { dismiss() })
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPicked: (UIImage) -> Void
        let dismiss: () -> Void

        init(onPicked: @escaping (UIImage) -> Void, dismiss: @escaping () -> Void) {
            self.onPicked = onPicked
            self.dismiss = dismiss
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                dismiss()
                return
            }
            let onPicked = self.onPicked
            let dismiss = self.dismiss
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                Task { @MainActor in
                    if let image = object as? UIImage {
                        onPicked(image)
                    }
                    dismiss()
                }
            }
        }
    }
}
