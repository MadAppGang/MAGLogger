//
//  MAGBackendLogSender.swift
//  SmartRun
//
//  Created by Yaroslav Symonenko on 30.07.2020.
//  Copyright © 2020 MadAppGang. All rights reserved.
//

import Foundation
import UIKit

public class MAGBackendLogSender {
    
    private let fileManager = FileManager.default
    private var entriesFileURL = URL(fileURLWithPath: "")
    private var sendingFileURL = URL(fileURLWithPath: "")
    private var sessionsFileURL = URL(fileURLWithPath: "")
    
    private var serverURL: URL
    private var appID: String?
    private var appSecret: String?
    private var minAllowedThreshold: Int
    private var sendToServerTimeout: TimeInterval

    private var points: Int = 0
    private var sendingInProgress = false
    private var initialSending = true
    private var sessionID = ""
    private(set) var queue: DispatchQueue

    
    public init(serverURL: URL, appID: String? = nil, appSecret: String? = nil, sendToServerTimeout: TimeInterval = 10, minAllowedThreshold: Int = 10) {
        self.serverURL = serverURL
        self.appID = appID
        self.appSecret = appSecret
        self.minAllowedThreshold = minAllowedThreshold
        self.sendToServerTimeout = sendToServerTimeout
        
        queue = DispatchQueue(label: "mag-backend-log-sender-queue", target: nil)
        
        if let baseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            entriesFileURL = baseURL.appendingPathComponent("mag_backend_logger_entries.json", isDirectory: false)
            sendingFileURL = baseURL.appendingPathComponent("mag_backend_logger_entries_sending.json", isDirectory: false)
            sessionsFileURL = baseURL.appendingPathComponent("mag_backend_logger_sessions.json", isDirectory: false)
        }
        
        startSession()
    }

    /// performs sending data to server
    private func sendNow() {
        if sendFileExists() {
            points = 0
        } else {
            if !renameJsonToSendFile() { return }
        }

        if !sendingInProgress {
            guard let logEntries = logsFromFile(sendingFileURL), logEntries.count > 0 else { return }

            sendingInProgress = true

            let payload = makePayload(with: logEntries)

            if let str = jsonStringFromDict(["sessions": payload]) {
                sendToServerAsync(str) { success in
                    if success {
                        self.cleanSessionList()
                        self.deleteFile(self.sendingFileURL)
                    }
                    self.sendingInProgress = false
                    self.points = 0
                }
            }
        }
    }

    /// performs network request to send data to server
    func sendToServerAsync(_ payloadStr: String, complete: @escaping (Bool) -> Void) {
        // create operation queue which uses current serial queue of destination
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue

        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: operationQueue)

        toNSLog("assembling request ...")

         // assemble request
        var request = URLRequest(url: serverURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: sendToServerTimeout)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add basic auth header if needs
        if let appID = appID, let appSecret = appSecret, let credentials = "\(appID):\(appSecret)".data(using: String.Encoding.utf8) {
            let base64Credentials = credentials.base64EncodedString(options: [])
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
        
        let params = ["payload": payloadStr]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            toNSLog("Error! Could not create JSON for server payload.")
            return complete(false)
        }
        toNSLog("sending params: \(params)")
        toNSLog("sending ...")

        // send request async to server on destination queue
        let task = session.dataTask(with: request) { _, response, error in
            self.toNSLog("received response from server")

            if let error = error {
                self.toNSLog("Error! Could not send entries to server. \(error)")
                complete(false)
            } else {
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        complete(true)
                    } else {
                        self.toNSLog("Error! Sending entries to server failed with status code \(response.statusCode)")
                        complete(false)
                    }
                }
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }

    /// initailzes new session
    private func startSession() {
        sessionID = UUID().uuidString
        
        var session = [String:Any]()

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionStr = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"

        session["os"] = "iOS"
        session["osVersion"] = osVersionStr
        session["hostName"] = ProcessInfo.processInfo.hostName
        session["deviceName"] = UIDevice.current.name
        session["deviceModel"] = deviceModel()
        session["appVersion"] = appVersion()
        session["appBuild"] = appBuild()
        session["sessionID"] = sessionID
        session["timestamp"] = Date().timeIntervalSince1970

        if let str = jsonStringFromDict(session) {
            saveToFile(str, url: sessionsFileURL)
        }
    }
    
    /// removes information about all sessions from storage except currrent session
    private func cleanSessionList() {
        let storedSessions = logsFromFile(sessionsFileURL)
        if let lastSession = storedSessions?.last, let str = jsonStringFromDict(lastSession) {
            saveToFile(str, url: sessionsFileURL, overwrite: true)
        }
    }
    
    /// prepares payload dictionary to send to servers
    private func makePayload(with logEntries: [[String: Any]]) -> [[String: Any]] {
        var payloadSessions = [[String:Any]]()
        
        let storedSessions = logsFromFile(sessionsFileURL)
        
        for logEntry in logEntries {
            guard let entrySessionID = logEntry["sessionID"] as? String else { continue }
            let preparedLogEntry = prepareLogEntry(logEntry)
                        
            if let payloadSessionIndex = payloadSessions.firstIndex(where: {
                guard let payloadSessionID = $0["sessionID"] as? String else { return false }
                return payloadSessionID == entrySessionID
            }) {
                if var sessionEntries = payloadSessions[payloadSessionIndex]["entries"] as? [[String:Any]] {
                    sessionEntries.append(preparedLogEntry)
                    payloadSessions[payloadSessionIndex]["entries"] = sessionEntries
                }
            } else {
                var session: [String:Any]!

                if let storedSession = storedSessions?.first(where: {
                    guard let storedSessionID = $0["sessionID"] as? String else { return false }
                    return storedSessionID == entrySessionID
                }) {
                    session = storedSession
                    session["entries"] = [preparedLogEntry]
                } else {
                    session = ["sessionID": "", "entries": [preparedLogEntry]]
                }
                payloadSessions.append(session)
            }
        }
        return payloadSessions
    }
    
    /// removes redundant fields from logEntry dictionary
    private func prepareLogEntry(_ logEntry: [String:Any]) -> [String:Any] {
        var preparedLogEntry = [String:Any]()
        for key in logEntry.keys {
            if key == "sessionID" { continue }
            preparedLogEntry[key] = logEntry[key]
        }
        return preparedLogEntry
    }
    
    /// turns dict into JSON-encoded string
    func jsonStringFromDict(_ dict: [String: Any]) -> String? {
        var jsonString: String?

        // try to create JSON string
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            jsonString = String(data: jsonData, encoding: .utf8)
        } catch {
            print("MAGLogger could not create JSON from dict.")
        }
        return jsonString
    }
    
    // MARK: File Handling
    
    /// appends a string as line to a file.
    /// returns boolean about success
    @discardableResult
    private func saveToFile(_ str: String, url: URL, overwrite: Bool = false) -> Bool {
        do {
            let line = str + "\n"

            if !fileManager.fileExists(atPath: url.path) || overwrite {
                try line.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            } else {
                let fileHandle = try FileHandle(forWritingTo: url)
                _ = fileHandle.seekToEndOfFile()

                if let data = line.data(using: String.Encoding.utf8) {
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            }
            return true
        } catch {
            return false
        }
    }

    /// Delete file to get started again
    @discardableResult
    func deleteFile(_ url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            toNSLog("Warning! Could not delete file \(url).")
        }
        return false
    }
    
    func sendFileExists() -> Bool {
        return fileManager.fileExists(atPath: sendingFileURL.path)
    }

    func renameJsonToSendFile() -> Bool {
        do {
            try fileManager.moveItem(at: entriesFileURL, to: sendingFileURL)
            return true
        } catch {
            return false
        }
    }

    /// returns optional array of log dicts from a file which has 1 json string per line
    func logsFromFile(_ url: URL) -> [[String: Any]]? {
        var lines = 0
        do {
            // try to read file, decode every JSON line and put dict from each line in array
            let fileContent = try String(contentsOfFile: url.path, encoding: .utf8)
            let linesArray = fileContent.components(separatedBy: "\n")
            var dicts = [[String: Any]()] // array of dictionaries
            for lineJSON in linesArray {
                lines += 1
                if lineJSON.first == "{" && lineJSON.last == "}" {
                    // try to parse json string into dict
                    if let data = lineJSON.data(using: .utf8) {
                        do {
                            if let dict = try JSONSerialization.jsonObject(with: data,
                                options: .mutableContainers) as? [String: Any] {
                                if !dict.isEmpty {
                                    dicts.append(dict)
                                }
                            }
                        } catch {
                            toNSLog("Error! Could not parse line \(lines) in file \(url).")
                        }
                    }
                }
            }
            dicts.removeFirst()
            return dicts
        } catch {
            toNSLog("Error! Could not read file \(url).")
        }
        return nil
    }

    // MARK: Utilites
    
    /// Returns the current app version string (like 1.2.5) or empty string on error
    private func appVersion() -> String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return version
        }
        return ""
    }

    /// Returns the current app build as integer (like 563, always incrementing) or 0 on error
    private func appBuild() -> Int {
        if let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            if let intVersion = Int(version) {
                return intVersion
            }
        }
        return 0
    }
    
    /// Returns string representation of device model
    private func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// Prints log to console
    private func toNSLog(_ string: String) {
        print("MAGLogger: \(string)")
    }
}


extension MAGBackendLogSender: MAGLogSender {
    
    func send(_ level: MAGLogger.LogLevel, tag: String, msg: String, thread: String, file: String, function: String, line: Int, context: Any?) {
        var dict: [String: Any] = [
            "sessionID": sessionID,
            "timestamp": Date().timeIntervalSince1970,
            "level": level.rawValue,
            "tag": tag,
            "message": msg,
            "thread": thread,
            "file": file.components(separatedBy: "/").last ?? "",
            "function": function,
            "line": line]
        
        if let cx = context { dict["context"] = cx }

        if let str = jsonStringFromDict(dict) {
            saveToFile(str, url: entriesFileURL)
            
            points += 1

            if points >= minAllowedThreshold {
                sendNow()
            } else if initialSending {
                initialSending = false
                
                if let logEntries = logsFromFile(entriesFileURL), logEntries.count > 1 {
                    sendNow()
                }
            }
        }
    }
}
