import Foundation

class AppwriteService {
    static let shared = AppwriteService()
    
    private let endpoint = "https://fra.cloud.appwrite.io/v1"
    private let projectId = "680c76af0037a7d23e44"
    private let databaseId = "680c778b000f055f6409"
    private let collectionId = "687250d70020221fb26c"
    
    func fetchSubscriptions() async throws -> [Subscription] {
        let urlString = "\(endpoint)/databases/\(databaseId)/collections/\(collectionId)/documents"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            if let errorText = String(data: data, encoding: .utf8) {
                print("Appwrite Error: \(errorText)")
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(AppwriteResponse<Subscription>.self, from: data)
        return result.documents
    }
}
