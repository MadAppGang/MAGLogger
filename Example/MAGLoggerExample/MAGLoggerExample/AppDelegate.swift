//
//  AppDelegate.swift
//  MAGLoggerExample
//
//  Created by Yaroslav Symonenko on 08.10.2020.
//

import UIKit
import MAGLogger

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupLogging()
        return true
    }
    
    private func setupLogging() {
        let logger = MAGLogger.self
        let logServerURL = URL(string: "https://webhook.site/d3d050ba-824a-42c7-888e-e76a68c344ff")! // URL of your log server
        let logSender = MAGBackendLogSender(serverURL: logServerURL, sendToServerTimeout: 30, minAllowedThreshold: 5)
        logger.logSender = logSender
    }
    
}

