import Foundation

class AppwriteService {
    static let shared = AppwriteService()
    
    private let endpoint = "https://sgp.cloud.appwrite.io/v1"
    private let projectId = "698212e50017eada99c8"
    private let databaseId = "69821743002139037da1"
    private let collectionId = "6982182b002e6a6680b4"
    
    func fetchSubscriptions() async throws -> [Subscription] {
        var components = URLComponents(string: "\(endpoint)/databases/\(databaseId)/collections/\(collectionId)/documents")!
        components.queryItems = [
            URLQueryItem(name: "queries[]", value: "{\"method\":\"limit\",\"values\":[100]}")
        ]
        guard let url = components.url else {
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
