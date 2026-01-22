
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
}
