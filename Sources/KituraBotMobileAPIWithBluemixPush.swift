//
//  KituraBotMobileAPIWithBluemixPush.swift
//  KituraBotMobileAPIWithBluemixPush
//
//  Created by Jacopo Mangiavacchi on 10/3/16.
//
//

import Foundation
import SwiftyJSON
import Kitura
import LoggerAPI
import KituraBot
import ToriAPNS


// MARK KituraBotMobileAPIWithBluemixPush

/// Implement Facebook Messenger Bot Webhook.
/// See [Facebook's documentation](https://developers.facebook.com/docs/messenger-platform/implementation#subscribe_app_pages)
/// for more information.
public class KituraBotMobileAPIWithBluemixPush : KituraBotProtocol {
    public var channelName: String?

    private var botProtocolMessageNotificationHandler: BotInternalMessageNotificationHandler?
    private let securityToken: String
    private let webHookPath: String
    private let push: APNS
    private let topic: String 
    
    
    
    /// Initialize a `KituraBotMobileAPIWithBluemixPush` instance.
    ///
    /// - Parameter securityToken: Arbitrary value used to validate a call.
    /// - Parameter webHookPath: URI for the Mobile API.
    public init(securityToken: String, webHookPath: String, filePathCrt: String, filePathKey: String, topic: String) {
        self.securityToken = securityToken
        self.webHookPath = webHookPath
        self.topic = topic

        let cert = APNSCertificate(certPath: filePathCrt, keyPath: filePathKey)
        self.push = APNS(withCerts: cert)
    }
    
    public func configure(router: Router, channelName: String, botProtocolMessageNotificationHandler: @escaping BotInternalMessageNotificationHandler) {
        self.channelName = channelName
        self.botProtocolMessageNotificationHandler = botProtocolMessageNotificationHandler
        
        router.post(webHookPath, handler: processRequestHandler)
    }
    
    //Send a text message using the internal Send API.
    //
    /// - Parameter recipientId: is the ios device push Token to send the Push Notification.
    public func sendTextMessage(recipientId: String, messageText: String, context: [String: Any]?) {
        let payload = APNSPayload(withText: messageText, ttl: 0, topic: topic, priority: .high)
        
        push.send(payload: payload, to: recipientId)
    }
    
    
    //PRIVATE REST API Handlers
    
    /// Exposed API to Send Message to the Bot client.
    /// Used from the Mobile App.
    ///
    /// INPUT JSON Payload
    /// {
    ///     "senderID" : "xxx",
    ///     "messageText" : "xxx",
    ///     "securityToken" : "xxx"
    ///     "context" : {}
    /// }
    ///
    /// OUTPUT JSON Payload
    /// {
    ///     "responseMessage" : "xxx",
    ///     "context" : {}
    /// }
    private func processRequestHandler(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        Log.debug("POST - process Bot request message from KituraBotMobileAPIWithBluemixPush")
        print("POST - process Bot request message from KituraBotMobileAPIWithBluemixPush")
        
        var data = Data()
        if try request.read(into: &data) > 0 {
            let json = JSON(data: data)
            if let senderID = json["senderID"].string, let msgText = json["messageText"].string, let accessToken = json["securityToken"].string {
                guard accessToken == securityToken else {
                    try response.status(.forbidden).end()
                    return
                }
                
                let context = json["context"].dictionaryObject
                
                if let (responseMessage, responseContext) = botProtocolMessageNotificationHandler?(channelName!, senderID, msgText, context) {
                    //Send JSON response for responseMessage
                    var jsonResponse = JSON([:])
                    jsonResponse["responseMessage"].stringValue = responseMessage

                    if let realContext = responseContext {
                        jsonResponse["context"].dictionaryObject = realContext
                    }
                    
                    try response.status(.OK).send(json: jsonResponse).end()
                }
                else {
                    try response.status(.OK).end()
                }

                return
            
            } else {
                Log.debug("Webhook received NO Valid data")
                print("Webhook received NO Valid data")
            }
        }
        
        try response.status(.notAcceptable).end()
    }

}


