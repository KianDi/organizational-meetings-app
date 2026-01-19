import SwiftUI
import UniformTypeIdentifiers

/// SwiftUI wrapper for UIDocumentPickerViewController
/// Enables native iOS document selection from Files app
struct DocumentPickerView: UIViewControllerRepresentable {
    // MARK: - Properties

    /// Callback invoked when user selects a document
    let onDocumentPicked: (URL) -> Void

    // MARK: - UIViewControllerRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentPicked: onDocumentPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Configure document picker with supported file types
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                .pdf,           // PDF documents
                .plainText,     // .txt files
                .text           // Generic text files
            ],
            asCopy: true        // Copy file to app sandbox
        )

        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false

        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }

    // MARK: - Coordinator

    /// Coordinator handles UIDocumentPickerDelegate callbacks
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentPicked: (URL) -> Void

        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onDocumentPicked(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled - no action needed
        }
    }
}
