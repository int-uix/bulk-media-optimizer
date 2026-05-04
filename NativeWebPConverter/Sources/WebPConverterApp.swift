import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct WebPConverterApp: App {
    @StateObject private var model = AppViewModel()

    var body: some Scene {
        WindowGroup("WebP Converter") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 620)
                .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
                    model.handleDrop(providers: providers)
                }
        }
        .defaultSize(width: 980, height: 680)
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @EnvironmentObject private var model: AppViewModel

    var body: some View {
        NavigationSplitView {
            Form {
                Section("Folders") {
                    pathRow(title: "Source", path: model.sourcePath) {
                        model.pickSourceFolder()
                    } openAction: {
                        model.openInFinder(model.sourcePath)
                    }

                    pathRow(title: "Destination", path: model.destinationPath) {
                        model.pickDestinationFolder()
                    } openAction: {
                        model.openInFinder(model.destinationPath)
                    }
                }

                Section("Options") {
                    Toggle("Create XLSX index", isOn: $model.makeXlsx)
                    Toggle("Use URL base for XLSX", isOn: $model.useUrlBase)
                        .disabled(!model.makeXlsx)

                    TextField("URL base", text: $model.urlBase)
                        .disabled(!model.makeXlsx || !model.useUrlBase)

                    TextField("Max width (optional)", text: $model.maxWidthText)
                }

                Section("Actions") {
                    HStack {
                        Button("Convert") { model.start() }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.isRunning)

                        Button("Cancel") { model.cancel() }
                            .buttonStyle(.bordered)
                            .disabled(!model.isRunning)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("WebP Converter")
            .navigationSplitViewColumnWidth(min: 280, ideal: 340)
        } detail: {
            VStack(alignment: .leading, spacing: 12) {
                Text(model.statusText)
                    .font(.headline)

                ProgressView(value: model.progressValue, total: model.progressTotal)

                HStack {
                    Text("Drop a folder anywhere in this window to set source.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Divider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(model.logs.indices, id: \.self) { idx in
                            Text(model.logs[idx])
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
        .alert("Permission Required", isPresented: Binding(
            get: { model.alertMessage != nil },
            set: { if !$0 { model.alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.alertMessage = nil }
        } message: {
            Text(model.alertMessage ?? "")
        }
    }

    @ViewBuilder
    private func pathRow(title: String, path: String, pickAction: @escaping () -> Void, openAction: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Text(path.isEmpty ? "Not selected" : path)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Spacer(minLength: 12)
                Button("Browse", action: pickAction)
                Button("Open", action: openAction).disabled(path.isEmpty)
            }
        }
    }
}
