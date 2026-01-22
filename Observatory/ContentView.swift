
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NASAViewModel()
    @State private var hovered = false
    
    var body: some View {
        ZStack {
            // Background Layer
            Color.black.ignoresSafeArea()
            
            if let item = viewModel.apodItem {
                AsyncImage(url: URL(string: item.url)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 60)
                            .opacity(0.3)
                            .animation(.easeInOut(duration: 0.5), value: item.date)
                    }
                }
                .ignoresSafeArea()
                .id(item.date)
            }
            
            // Main Content Layer
            VStack(spacing: 30) {
                
                // 1. Two-Column Layout
                HStack(alignment: .top, spacing: 30) {
                    
                    // Left Column: Image Area
                    ZStack {
                        if let item = viewModel.apodItem {
                            // 2. Fixed specific handling for AsyncImage stability
                            AsyncImage(url: URL(string: item.hdurl ?? item.url)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 400, maxHeight: 600) // Reserved space
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                                        .onHover { isHovering in
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                hovered = isHovering
                                            }
                                        }
                                        .scaleEffect(hovered ? 1.01 : 1.0)
                                        // Ensure image respects the container constraints
                                        .frame(maxWidth: .infinity, minHeight: 400, maxHeight: 600)
                                case .failure:
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, minHeight: 400, maxHeight: 600)
                                @unknown default:
                                    EmptyView()
                                        .frame(maxWidth: .infinity, minHeight: 400, maxHeight: 600)
                                }
                            }
                            .transition(.opacity.animation(.easeInOut))
                            .id(item.date)
                        } else if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                                .frame(maxWidth: .infinity, minHeight: 400, maxHeight: 600)
                        } else if let error = viewModel.errorMessage {
                            VStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.red)
                                Text(error)
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    Task { await viewModel.fetchAPOD() }
                                }
                                .padding(.top)
                            }
                            .frame(maxWidth: .infinity, minHeight: 400, maxHeight: 600)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 400, maxHeight: 600) // Fixed container
                    .clipped() // 4. Clipping
                    
                    // Right Column: Sidebar
                    if let item = viewModel.apodItem {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // Title
                            Text(item.title)
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                            
                            // Date
                            Text(item.date)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                            
                            // Refresh Button
                            Button(action: {
                                Task { await viewModel.fetchAPOD() }
                            }) {
                                Label("Refresh Day", systemImage: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                            
                            // Explanation
                            ScrollView(showsIndicators: false) {
                                Text(item.explanation)
                                    .font(.system(size: 15, weight: .regular, design: .default))
                                    .lineSpacing(7)
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                if let copyright = item.copyright {
                                    Text("Image Credit: \(copyright)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 20)
                                }
                            }
                            

                        }
                        .frame(width: 350) // 3. Sidebar Locking
                        .frame(maxHeight: .infinity) // Ensure sidebar stretches if needed
                        .padding(.vertical, 10)
                    }
                }
                
                // 3. Modern History Bar (Always Visible / Placeholder)
                VStack {
                    if !viewModel.historyItems.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.historyItems) { historyItem in
                                    Button(action: {
                                        viewModel.selectItem(historyItem)
                                    }) {
                                        AsyncImage(url: URL(string: historyItem.url)) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } else {
                                                Color.white.opacity(0.05)
                                            }
                                        }
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    viewModel.apodItem?.date == historyItem.date ? Color.blue : Color.clear,
                                                    lineWidth: viewModel.apodItem?.date == historyItem.date ? 3 : 0
                                                )
                                        )
                                        .shadow(radius: viewModel.apodItem?.date == historyItem.date ? 8 : 0)
                                        .scaleEffect(viewModel.apodItem?.date == historyItem.date ? 1.05 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.apodItem?.date)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(16)
                        }
                    } else {
                        // Placeholder / Skeleton Loading State
                        HStack(spacing: 12) {
                            ForEach(0..<7, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 70, height: 70)
                            }
                        }
                        .padding(16)
                    }
                }
                .frame(height: 102) // Fixed height to prevent jumps
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(40) // 4. Global Window Padding
        }
        .frame(minWidth: 1000, minHeight: 700)
        .background(Color.black)
        .onAppear {
            // Run in parallel
            Task {
                await viewModel.fetchAPOD()
            }
            Task {
                await viewModel.fetchHistory()
            }
        }
    }
}

#Preview {
    ContentView()
}
