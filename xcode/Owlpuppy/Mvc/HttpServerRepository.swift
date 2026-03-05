//
//  HttpServer.swift
//  Owlpuppy
//
//  Created by Manabu Tonosaki on 2026-03-05.
//

import Foundation
import Network

class HttpServerRepository: ServerRepository {
    private let tcpipListener: NWListener
    private let portNumber: NWEndpoint.Port = 9988
    private var callback: ((HTTPRequest) -> HTTPResponse)?
    
    init() throws {
        tcpipListener = try NWListener(using: .tcp, on: portNumber)
    }
    
    func start(callback: @escaping (HTTPRequest) -> HTTPResponse) {
        self.callback = callback
        
        tcpipListener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Start listening http://localhost:\(self.portNumber)")

            case .failed(let error):
                print("Error: Server failed: \(error)")

            default:
                break
            }
        }
        
        tcpipListener.newConnectionHandler = { connection in
            self.handleConnection(connection)
        }
        
        tcpipListener.start(queue: .global(qos: .userInitiated))
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data = data, let request = String(data: data, encoding: .utf8) {
                self.processRequest(request, connection: connection)
                
            } else if let error = error {
                print("Error: Receive connection data: \(error)")
                connection.cancel()
            }
        }
    }
    
    private func processRequest(_ requestString: String, connection: NWConnection) {
        let lines = requestString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            connection.cancel()
            return
        }
        
        if firstLine.hasPrefix("OPTIONS") {
            let optionsResponse = """
            HTTP/1.1 200 OK\r
            Access-Control-Allow-Origin: *\r
            Access-Control-Allow-Methods: POST, OPTIONS\r
            Access-Control-Allow-Headers: Content-Type\r
            Connection: close\r
            \r\n
            """
            
            sendResponse(optionsResponse, connection: connection)
            return // OPTIONSの時はここで処理を終わらせる
        }
        
        let firstLineParts = firstLine.split(separator: " ")
        guard firstLineParts.count >= 2,
              let method = HTTPMethod(rawValue: String(firstLineParts[0])) else {
            connection.cancel()
            return
        }
        let path = String(firstLineParts[1])
        
        var body = ""
        if let range = requestString.range(of: "\r\n\r\n") {
            body = String(requestString[range.upperBound...])
        }
        
        let request = HTTPRequest(method: method, path: path, body: body)
        guard let response = self.callback?(request) else {
            print("Fatal Error: callback is not implemented yet.")
            connection.cancel()
            return
        }
        
        connection.send(content: response.rawData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
    
    private func sendResponse(_ responseString: String, connection: NWConnection) {
        let data = responseString.data(using: .utf8)
        connection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("Error in sending response: \(error)")
            }
            connection.cancel()
        }))
    }
}
