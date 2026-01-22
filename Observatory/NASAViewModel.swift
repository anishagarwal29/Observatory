
import Combine
import Foundation
import AppKit
import SwiftUI

@MainActor
class NASAViewModel: ObservableObject {
    
    @Published var apodItem: APODItem?
    @Published var historyItems: [APODItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // API Details
    private let apiKey = "agy146lImSGWLXV6zUkNbGCKMqdwoQX6LUnGWfex"
    private let baseURL = "https://api.nasa.gov/planetary/apod"
    
    func fetchAPOD() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)?api_key=\(apiKey)") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let item = try decoder.decode(APODItem.self, from: data)
            self.apodItem = item
        } catch {
            errorMessage = "Failed to fetch data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func fetchHistory() async {
        // Don't modify isLoading here to avoid blocking the main view if it loads separately,
        // or strictly manage it if you want the whole UI to wait.
        // For a sidebar/bottom bar, silent loading is often better, or a separate loading state.
        // But user instructions didn't specify separate loading. I'll leave isLoading alone or use a local loading?
        // Let's use the main loading state initially if fetching everything, or just let it load.
        // I will keep it independent of the main 'isLoading'spinner to not hide the main image if it's already there.
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -7, to: today) else { return }
        
        let startDate = dateFormatter.string(from: start)
        let endDate = dateFormatter.string(from: today)
        
        guard let url = URL(string: "\(baseURL)?api_key=\(apiKey)&start_date=\(startDate)&end_date=\(endDate)") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let items = try decoder.decode([APODItem].self, from: data)
            // Sort by date descending (newest first)
            self.historyItems = items.sorted { $0.date > $1.date }
        } catch {
            print("Failed to fetch history: \(error.localizedDescription)")
            // We might not want to show a blocking error for history if the main image works.
        }
    }
    
    func selectItem(_ item: APODItem) {
        withAnimation {
            self.apodItem = item
        }
    }
    
    func setWallpaper() {
        guard let hdurl = apodItem?.hdurl ?? apodItem?.url, let url = URL(string: hdurl) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // Save to temporary file
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("apod_wallpaper.jpg")
                try data.write(to: tempURL)
                
                // Set wallpaper
                if let screen = NSScreen.main {
                     try NSWorkspace.shared.setDesktopImageURL(tempURL, for: screen, options: [:])
                }
            } catch {
                print("Failed to set wallpaper: \(error)")
            }
        }
    }
}
