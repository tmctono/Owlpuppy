//
//  Controller.swift
//  Owlpuppy
//
//  Created by Manabu Tonosaki on 2026-03-05.
//


import Foundation
import Network

protocol Controller {
    var path: String { get }
    var method: HTTPMethod { get }
    func request(request: HTTPRequest) -> HTTPResponse
}

class BaseController<Service: ServiceProtocol>: Controller {
    var path: String { fatalError("NOT IMPLEMENTED") }
    var method: HTTPMethod { fatalError("NOT IMPLEMENTED") }
    
    let singletonServiceInstance: Service
    
    init(service: Service) {
        self.singletonServiceInstance = service
    }
    
    func request(request: HTTPRequest) -> HTTPResponse {
        do {
            guard let jsonData = request.body.data(using: .utf8) else {
                return HTTPResponse(statusCode: 400, body: "Bad Request")
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let parsedModel = try decoder.decode(Service.ModelType.self, from: jsonData)
            
            let isSuccess = singletonServiceInstance.service(model: parsedModel)
            
            if isSuccess {
                return HTTPResponse(statusCode: 200, body: "OK")
            } else {
                return HTTPResponse(statusCode: 500, body: "Internal Server Error")
            }
        }
        catch {
            print("Parse Error: \(error)")
            return HTTPResponse(statusCode: 400, body: "Bad Request: JSON Parse Error")
        }
    }
}


enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

struct HTTPRequest {
    let method: HTTPMethod
    let path: String
    let body: String
}

struct HTTPResponse {
    let statusCode: Int
    let body: String
    
    var rawData: Data {
        let statusText = statusCode == 200 ? "OK" : "Not Found"
        let responseString = "HTTP/1.1 \(statusCode) \(statusText)\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text/plain\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
        return responseString.data(using: .utf8) ?? Data()
    }
}
