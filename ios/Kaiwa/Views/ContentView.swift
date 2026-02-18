import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SessionViewModel()
    @State private var showingSetup = true

    var body: some View {
        if showingSetup {
            SetupView(viewModel: viewModel) {
                showingSetup = false
            }
        } else {
            SessionView(viewModel: viewModel) {
                showingSetup = true
            }
        }
    }
}
