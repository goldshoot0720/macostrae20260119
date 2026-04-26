import Foundation

private enum AppwriteConfig {
    static let endpoint = "https://sgp.cloud.appwrite.io/v1"
    static let projectId = "698212e50017eada99c8"
    static let databaseId = "69821743002139037da1"
    static let tableId = "69d927310016a98cc2db"
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
        let endpoint = setting("NEXT_PUBLIC_APPWRITE_ENDPOINT", fallback: AppwriteConfig.endpoint)
        let projectId = setting("NEXT_PUBLIC_APPWRITE_PROJECT_ID", fallback: AppwriteConfig.projectId)
        let databaseId = setting("APPWRITE_DATABASE_ID", fallback: AppwriteConfig.databaseId)
        let tableId = setting("APPWRITE_TABLE_ID", fallback: setting("APPWRITE_COLLECTION_ID", fallback: AppwriteConfig.tableId))

        var components = URLComponents(string: "\(endpoint)/tablesdb/\(databaseId)/tables/\(tableId)/rows")!
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
        let result = try decoder.decode(AppwriteRowsResponse<Subscription>.self, from: data)
        return result.rows
    }
    
    private func httpResponseStatusCode(from response: URLResponse) -> Int {
        (response as? HTTPURLResponse)?.statusCode ?? -1
    }

    private func setting(_ name: String, fallback: String) -> String {
        guard let value = ProcessInfo.processInfo.environment[name], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallback
        }

        return value
    }
}
