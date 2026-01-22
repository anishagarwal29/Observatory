
import Foundation

struct APODItem: Codable, Identifiable {
    var id: String { date }
    let title: String
    let explanation: String
    let url: String
    let hdurl: String?
    let date: String
    let copyright: String?
    let mediaType: String
    
    enum CodingKeys: String, CodingKey {
        case title, explanation, url, hdurl, date, copyright
        case mediaType = "media_type"
    }
    
    var formattedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        if let dateObj = inputFormatter.date(from: date) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "dd-MM-yyyy"
            return outputFormatter.string(from: dateObj)
        }
        
        return date
    }
}
