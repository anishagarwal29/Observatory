
import SwiftUI

/// Main content view for the Observatory app.
/// Uses the modern .inspector API for a native macOS detail panel.
struct ContentView: View {
    @StateObject private var viewModel = NASAViewModel()
    @State private var isInspectorPresented = true
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 1. Background
                Color.black.ignoresSafeArea()
                
                // 2. Main Content Area (Center Image)
                VStack {
                    Spacer()
                    
                    if let item = viewModel.apodItem {
                        if item.mediaType == "video" {
                             videoPlaceholder(for: item)
                                .frame(maxWidth: 800, maxHeight: 600)
                                .padding(20)
                        } else {
                            // KEY FIX: The ID ensures the View IDENTITY changes when the URL changes.
                            // This forces SwiftUI to discard the old AsyncImage immediately and start fresh,
                            // showing the placeholder (empty phase) instanty.
                            AsyncImage(url: URL(string: item.hdurl ?? item.url)) { phase in
                                switch phase {
                                case .empty:
                                    // Loading State - Explicitly visible immediately on change
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white.opacity(0.05))
                                        ProgressView()
                                            .scaleEffect(1.5)
                                            .tint(.white)
                                    }
                                    .aspectRatio(16/9, contentMode: .fit) // Maintain a reasonable aspect ratio while loading
                                    .padding(20)
                                case .success(let image):
                                    // The Main Event
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                                        .padding(20) // Reduced padding to make image larger
                                        .transition(.opacity.animation(.easeInOut))
                                case .failure:
                                    // Error State
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white.opacity(0.05))
                                        
                                        VStack(spacing: 16) {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.largeTitle)
                                                .foregroundColor(.red)
                                            Text("Failed to load high-res image")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .aspectRatio(16/9, contentMode: .fit)
                                    .padding(20)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .id(item.url) // CRITICAL: This forces the "Hard Reset"
                        }
                    } else {
                        // Global Loading State (Initial App Load)
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                    
                    Spacer()
                    
                    // Spacer for the floating history bar height so image doesn't get covered
                    // 120 (height) + 20 (padding)
                    Color.clear.frame(height: 140)
                }
                
                // 3. Floating History Bar
                historyBar
                    .padding(.bottom, 20)
            }
            .toolbar {
                // Toolbar Items
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task { await viewModel.fetchAPOD() }
                    }) {
                        Label("Refresh Day", systemImage: "arrow.clockwise")
                    }
                    .help("Load a random APOD")
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        withAnimation {
                            isInspectorPresented.toggle()
                        }
                    }) {
                        Label("Toggle Inspector", systemImage: "sidebar.right")
                    }
                    .help("Show/Hide details")
                }
            }
        }
        // 4. The Inspector
        .inspector(isPresented: $isInspectorPresented) {
            InspectorView(item: viewModel.apodItem)
                .inspectorColumnWidth(min: 300, ideal: 350, max: 450) // Slightly wider ideal width
                .toolbar {
                    // Start sidebar content from the top
                    Spacer()
                }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            Task { await viewModel.fetchAPOD() }
            Task { await viewModel.fetchHistory() }
        }
    }
    
    // MARK: - History Component
    
    private var historyBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if viewModel.historyItems.isEmpty {
                    ForEach(0..<8, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 70, height: 70)
                    }
                } else {
                    ForEach(viewModel.historyItems) { historyItem in
                        Button {
                            // Updating the view model triggers the ID change on the main image
                            viewModel.selectItem(historyItem)
                        } label: {
                            AsyncImage(url: URL(string: historyItem.url)) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Color.white.opacity(0.1)
                                }
                            }
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        viewModel.apodItem?.date == historyItem.date ? Color.blue : Color.white.opacity(0.2),
                                        lineWidth: viewModel.apodItem?.date == historyItem.date ? 3 : 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 40) // Keep it centered-ish
    }
    
    // MARK: - Video Placeholder
    
    private func videoPlaceholder(for item: APODItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
            
            VStack(spacing: 16) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.8))
                
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                if let url = URL(string: item.url) {
                    Link(destination: url) {
                        Label("Watch Video in Browser", systemImage: "safari")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Inspector View Structure

struct InspectorView: View {
    let item: APODItem?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let item = item {
                    // Date Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.formattedDate)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.secondary)
                        
                        Text(item.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    
                    Divider()
                    
                    // Description
                    Text("Explanation")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(item.explanation)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundStyle(.primary.opacity(0.9))
                    
                    // Copyright
                    if let copyright = item.copyright {
                        Divider()
                        HStack {
                            Image(systemName: "camera")
                            Text(copyright)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                } else {
                    ProgressView("Loading details...")
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    ContentView()
}
