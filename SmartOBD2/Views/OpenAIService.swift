//
//  OpenAIService.swift
//  SmartOBD2
//
//  Created by kemo konteh on 8/18/23.
//

import Foundation
import Alamofire


class OpenAIService {
    private let url = "https://api.openai.com/v1/chat/completions"
    func sendMessage(messages: [Message]) async -> OpenAIChatResponse? {
        let openAIChatBody = messages.map({ OpenAIChatMessage(role: $0.role, content: $0.content) })
        let body = OpenAIChatBody(model: "gpt-3.5-turbo", messages: openAIChatBody)

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Constants.openAIApiKey)",
        ]

        return try? await AF.request(url, method: .post, parameters: body, encoder: .json, headers: headers).serializingDecodable(OpenAIChatResponse.self).value
    }
}


struct OpenAIChatBody: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
}

struct OpenAIChatMessage: Codable {
    let role: SenderRole
    let content: String
}
enum SenderRole: String, Codable {
    case system
    case user
    case assistant
}

struct OpenAIChatResponse: Decodable {
    let choices: [OpenAIChatResponseChoice]
}

struct OpenAIChatResponseChoice: Decodable {
    let message: OpenAIChatMessage
}
