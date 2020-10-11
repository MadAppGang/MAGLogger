//
//  ViewController.swift
//  MAGLoggerExample
//
//  Created by Yaroslav Symonenko on 08.10.2020.
//

import UIKit
import MAGLogger

final class ViewController: UIViewController {

    @IBOutlet private var logLevelSegmentedControl: UISegmentedControl!
    @IBOutlet private var tagTextField: UITextField!
    @IBOutlet private var messageTextField: UITextField!
    
    private let logger = MAGLogger.self
    
    
    // MARK: - Common functions
    
    private func showCompletionAlert() {
        let alertController = UIAlertController(title: "Attention", message: "Log entry was added", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func addLogEntry(payload: Any? = nil) {
        let logLevel = MAGLogger.LogLevel(rawValue: logLevelSegmentedControl.selectedSegmentIndex) ?? MAGLogger.LogLevel.verbose
        let logEntryTag = tagTextField.text ?? ""
        let logMessage = messageTextField.text ?? ""
        
        // logMessage can be of any type, not just a string (for instance - Int, Array, Dictionary etc.)
        switch logLevel {
        case .verbose:
            logger.verbose(logEntryTag, logMessage, context: payload)
        case .debug:
            logger.debug(logEntryTag, logMessage, context: payload)
        case .info:
            logger.info(logEntryTag, logMessage, context: payload)
        case .warning:
            logger.warning(logEntryTag, logMessage, context: payload)
        case .error:
            logger.error(logEntryTag, logMessage, context: payload)
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func actionSendWithPayload() {
        let somePayload: [String : Any] = ["user_id" : 12345, "user_name" : "Test user"]
        addLogEntry(payload: somePayload)
        
        showCompletionAlert()
    }
    
    @IBAction private func actionSendWithoutPayload() {
        addLogEntry()
        
        showCompletionAlert()
    }
    
}

