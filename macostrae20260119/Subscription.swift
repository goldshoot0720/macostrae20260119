import Foundation

struct Subscription: Identifiable, Codable {
    let id: String
    let name: String
    let site: String?
    let price: Int
    let nextdate: String
    let note: String?
    let account: String?
    let currency: String?
    let shouldContinue: Bool?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case name
        case site
        case price
        case nextdate
        case note
        case account
        case currency
        case shouldContinue = "continue"
        case createdAt = "$createdAt"
        case updatedAt = "$updatedAt"
    }
}

struct AppwriteResponse<T: Codable>: Codable {
    let total: Int
    let documents: [T]
}
