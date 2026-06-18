import SwiftUI

struct ContentView: View {
    @State private var viewModel = LinterViewModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            editor
            Divider()
            footer
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button("Format") {
                viewModel.format()
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(!viewModel.canFormat)

            Button("Clear") {
                viewModel.clear()
            }

            Spacer()

            statusBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var statusBadge: some View {
        Text(viewModel.statusBadgeText)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusBadgeColor.opacity(0.15))
            .foregroundStyle(statusBadgeColor)
            .clipShape(Capsule())
    }

    private var statusBadgeColor: Color {
        switch viewModel.status {
        case .neutral:
            return .secondary
        case .valid:
            return .green
        case .invalid:
            return .red
        }
    }

    private var editor: some View {
        TextEditor(text: $viewModel.text)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(12)
            .background(Color(nsColor: .textBackgroundColor))
            .onChange(of: viewModel.text) { _, _ in
                viewModel.textDidChange()
            }
    }

    private var footer: some View {
        HStack {
            Text(viewModel.footerMessage)
                .font(.caption)
                .foregroundStyle(footerColor)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var footerColor: Color {
        switch viewModel.status {
        case .neutral:
            return .secondary
        case .valid:
            return .green
        case .invalid:
            return .red
        }
    }
}
