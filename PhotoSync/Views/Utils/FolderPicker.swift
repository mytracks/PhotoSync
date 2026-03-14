//
//  FolderPicker.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 14.03.26.
//

#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers

struct FolderPicker: UIViewControllerRepresentable {
    /// Called with the URL the user selected
    var onFolderPicked: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFolderPicked: onFolderPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFolderPicked: (URL) -> Void

        init(onFolderPicked: @escaping (URL) -> Void) {
            self.onFolderPicked = onFolderPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let folderURL = urls.first else { return }
            onFolderPicked(folderURL)
        }
    }
}
#endif

