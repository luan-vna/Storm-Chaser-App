import SwiftUI
import UIKit

struct NewReportPhotoSection: View {
    let capturedImage: UIImage?
    let onCamera: () -> Void
    let onLibrary: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if let capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 180)
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Capture or pick a photo")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 8) {
                Button(action: onCamera) {
                    Label("Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                Button(action: onLibrary) {
                    Label("Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}
