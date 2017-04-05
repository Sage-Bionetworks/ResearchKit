/*
 Copyright (c) 2017, Sage Bionetworks. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


import WatchConnectivity
import WatchKit
import Foundation


/**
 `ORKPhoneConnector` is a self-retaining singleton that can track and forward messages from the 
 phone.
 
 When attempting to send a message from the watch to the phone, if the watch cannot connect to the 
 phone, then it will timeout eventually, *but* that timeout is more that 2 minutes and cannot be 
 adjusted by the developer. This means that using the callback can hang the UI while it is waiting 
 for a response. Instead, this class use a fire-and-forget pattern with a self-retaining singleton 
 to track the messages. Thus, a message can be sent once a connection is established, even if the 
 workout that sent the message has finished and the object has been released.
 */
public final class ORKPhoneConnector: NSObject, WCSessionDelegate {
    
    public static let shared = ORKPhoneConnector()
    
    // Only allow singleton init. 
    private override init() {
        super.init()
    }
    
    // Link to a workout connector that might be listening for messages.
    weak var workoutConnector: ORKWorkoutConnector? {
        didSet {
            if workoutConnector != nil {
                flushPending()
            }
        }
    }
    
    fileprivate var connectivitySession: WCSession?
    fileprivate var connecting = false
    fileprivate var messagesToSend = [MessageHandler]()
    
    /**
     Send a message to the phone.
     
     @param message             The dictionary with the message.
     */
    public func send(message: ORKWorkoutMessage) {
        
        debug_print("CALLED: send(message: \(message))")
        
        let replyHandler:(([String : Any]) -> Swift.Void)? = { (reply) in
            debug_print("message sent: \(message) reply: \(reply)")
        }
        
        let errHandler: ((Error) -> Swift.Void)? = { (error) in
            debug_print("Failed to send message: \(message) error: \(error)")
        }
        
        let messageHandler = MessageHandler(message: message, replyHandler: replyHandler, errorHandler: errHandler)
        
        DispatchQueue.main.async {
            self.messagesToSend.append(messageHandler)
            self.sendPending()
        }
    }

    private func sendPending() {
        
        if let session = self.connectivitySession, session.activationState == .activated, session.isReachable {
            // Connection established. Send all pending messages.
            debug_print("Connection established. Sending pending messages.")
            for message in self.messagesToSend {
                session.sendMessage(message.message.dictionaryRepresentation(),
                                    replyHandler: message.replyHandler, errorHandler: message.errorHandler)
            }
            self.messagesToSend.removeAll()
            
        } else if !connecting &&
            ((self.connectivitySession == nil) || (self.connectivitySession!.activationState == .notActivated)) {
            // Session activation has not been attempted or disconect is finished
            debug_print("Attempting connection.")
            connecting = true
            let session = WCSession.default()
            session.delegate = self
            session.activate()
            
        } else {
            // If the message got here while a connection is being established, then retry with w/ delay
            debug_print("Connection activated. Waiting for change in reachability.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                self.sendPending()
            })
        }
    }
    
    private func flushPending() {
        DispatchQueue.main.async {
            self.messagesToSend.removeAll()
        }
    }
    
    func respondWithFailed(error: Error?) {
        let err = error!
            
            //WCError.notReachable
        for message in self.messagesToSend {
            message.errorHandler?(err)
        }
        self.messagesToSend.removeAll()
    }
    
    
    // MARK : WCSessionDelegate
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        self.connecting = false
        self.connectivitySession = session
        DispatchQueue.main.async {
            if activationState == .activated {
                self.sendPending()
            } else {
                print("Watch connector \(session): activationDidCompleteWith: \(activationState) error: \(String(describing: error))")
                self.respondWithFailed(error: error)
            }
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        debug_print("Watch connector \(session): sessionReachabilityDidChange")
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.workoutConnector?.messageReceived(message: message)
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Swift.Void) {
        DispatchQueue.main.async {
            self.workoutConnector?.messageReceived(message: message, replyHandler: replyHandler)
        }
    }
}

fileprivate class MessageHandler: NSObject {
    
    let message: ORKWorkoutMessage
    let replyHandler: (([String : Any]) -> Swift.Void)?
    let errorHandler: ((Error) -> Swift.Void)?
    
    init(message: ORKWorkoutMessage, replyHandler: (([String : Any]) -> Swift.Void)?, errorHandler: ((Error) -> Swift.Void)?) {
        self.message = message
        self.replyHandler = replyHandler
        self.errorHandler = errorHandler
        super.init()
    }
}

