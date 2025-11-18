//
//  APIClient.swift
//  HappyLaunderer
//
//  Base API client for making network requests
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(String)
    case unauthorized
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class APIClient {
    static let shared = APIClient()
    
    private init() {}
    
    private let session = URLSession.shared
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    // MARK: - Generic Request Methods
    
    func get<T: Decodable>(
        endpoint: String,
        token: String? = nil
    ) async throws -> T {
        return try await request(endpoint: endpoint, method: "GET", token: token)
    }
    
    func post<T: Decodable, Body: Encodable>(
        endpoint: String,
        body: Body,
        token: String? = nil
    ) async throws -> T {
        return try await request(endpoint: endpoint, method: "POST", body: body, token: token)
    }
    
    func put<T: Decodable, Body: Encodable>(
        endpoint: String,
        body: Body,
        token: String? = nil
    ) async throws -> T {
        return try await request(endpoint: endpoint, method: "PUT", body: body, token: token)
    }
    
    func delete<T: Decodable>(
        endpoint: String,
        token: String? = nil
    ) async throws -> T {
        return try await request(endpoint: endpoint, method: "DELETE", token: token)
    }
    
    // MARK: - Private Helper Methods
    
    private func request<T: Decodable, Body: Encodable>(
        endpoint: String,
        method: String,
        body: Body? = nil,
        token: String? = nil
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try jsonEncoder.encode(body)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try jsonDecoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            case 401:
                throw APIError.unauthorized
            default:
                if let errorResponse = try? jsonDecoder.decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.error)
                } else {
                    throw APIError.serverError("Server error: \(httpResponse.statusCode)")
                }
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Error Response Model
struct ErrorResponse: Codable {
    let error: String
    let details: [String]?
}

