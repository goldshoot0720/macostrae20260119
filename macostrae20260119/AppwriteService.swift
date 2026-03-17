import Foundation

private enum AppwriteConfig {
    static let endpoint = "https://sgp.cloud.appwrite.io/v1"
    static let projectId = "698212e50017eada99c8"
    static let databaseId = "69821743002139037da1"
    static let collectionId = "69b24465002d43df9b00"
    static let bucketId = "698215640037d1a67e6b"
    // Intentionally do not embed APPWRITE_API_KEY in the client app.
    // Server keys should stay on a trusted backend only.
}

private struct AppwriteErrorResponse: Decodable {
    let message: String
    let code: Int?
    let type: String?
}

class AppwriteService {
    static let shared = AppwriteService()
    
    func fetchSubscriptions() async throws -> [Subscription] {
        var components = URLComponents(string: "\(AppwriteConfig.endpoint)/databases/\(AppwriteConfig.databaseId)/collections/\(AppwriteConfig.collectionId)/documents")!
        components.queryItems = [
            URLQueryItem(name: "queries[]", value: "{\"method\":\"limit\",\"values\":[100]}")
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(AppwriteConfig.projectId, forHTTPHeaderField: "X-Appwrite-Project")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            if let appwriteError = try? JSONDecoder().decode(AppwriteErrorResponse.self, from: data) {
                throw NSError(
                    domain: "AppwriteService",
                    code: httpResponseStatusCode(from: response),
                    userInfo: [
                        NSLocalizedDescriptionKey: "Appwrite \(appwriteError.code ?? httpResponseStatusCode(from: response)): \(appwriteError.message)"
                    ]
                )
            }
            
            if let errorText = String(data: data, encoding: .utf8), !errorText.isEmpty {
                throw NSError(
                    domain: "AppwriteService",
                    code: httpResponseStatusCode(from: response),
                    userInfo: [NSLocalizedDescriptionKey: errorText]
                )
            }
            
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(AppwriteResponse<Subscription>.self, from: data)
        return result.documents
    }
    
    private func httpResponseStatusCode(from response: URLResponse) -> Int {
        (response as? HTTPURLResponse)?.statusCode ?? -1
    }
}
