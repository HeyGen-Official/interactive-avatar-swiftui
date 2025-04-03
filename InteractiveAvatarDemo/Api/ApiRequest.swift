//
//  ApiRequest.swift
//  InteractiveAvatarDemo
//
//  Created by Hwan Moon Lee on 3/18/25.
//

import Foundation
import Alamofire

struct ApiRequest<ResponseType: Decodable> {
    var baseUrl: String = ApiConfig.baseUrl
    let endpoint: String
    let method: HTTPMethod
    var parameters: Parameters? = nil
    var headers: HTTPHeaders = HTTPHeaders()
    var decoder: JSONDecoder = JSONDecoder.apiResponseDecoder
}

extension JSONDecoder {
    static var apiResponseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

extension ApiRequest {
    var requestUrl: String {
        "\(baseUrl)\(endpoint)"
    }
    var encoding: ParameterEncoding {
        (method == .get || method == .delete) ? URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .literal) : JSONEncoding.default
    }
}

extension ApiRequest {
    func request() async throws -> ResponseType {
        return try await withCheckedThrowingContinuation { continuation in
            var headers = self.headers
            headers.add(name: "x-api-key", value: ApiConfig.apiKey)
            AF.request(requestUrl,
                       method: method,
                       parameters: parameters,
                       encoding: encoding,
                       headers: headers)
            .validate(statusCode: 200..<300)
            .responseData { response in
                do {
                    switch response.result {
                    case .success(let data):
                        print ("\(String(data: data, encoding: .utf8) ?? "")")
                        let decodedResponse = try decoder.decode(ResponseType.self, from: data)
                        continuation.resume(returning: decodedResponse)
                    case .failure(let error):
                        print(error)
                        continuation.resume(throwing: error)
                    }
                } catch {
                    print(error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

protocol RequestParamsProtocol: Codable {
    func asDictionary() -> [String: Any]
}

extension RequestParamsProtocol {
    func asDictionary() -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let data = try? encoder.encode(self),
              let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return [:]
        }
        return dictionary
    }
}
