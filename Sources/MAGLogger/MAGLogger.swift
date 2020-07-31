//
//  MAGLogger.swift
//  SmartRun
//
//  Created by Yaroslav Symonenko on 24.07.2020.
//  Copyright © 2020 MadAppGang. All rights reserved.
//

import Foundation
import UIKit


protocol MAGLogSender {
    
    var queue: DispatchQueue { get }
    
    func send(_ level: MAGLogger.LogLevel, tag: String, msg: String, thread: String, file: String, function: String, line: Int, context: Any?)
}


final class MAGLogger {
    
    enum LogLevel: Int {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
    }
    
    static var logSender: MAGLogSender?
    
    
    class func verbose(_ tag: String, _ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        custom(.verbose, tag, message(), file, function, line: line, context: context)
    }

    class func debug(_ tag: String, _ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        custom(.debug, tag, message(), file, function, line: line, context: context)
    }
    
    class func info(_ tag: String, _ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        custom(.info, tag, message(), file, function, line: line, context: context)
    }
    
    class func warning(_ tag: String, _ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        custom(.warning, tag, message(), file, function, line: line, context: context)
    }
    
    class func error(_ tag: String, _ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        custom(.error, tag, message(), file, function, line: line, context: context)
    }
    
    /// common function for logging
    private class func custom(_ level: LogLevel, _ tag: String, _ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) {
        guard let logSender = logSender else { return }
        
        let msgStr = "\(message())"
        let threadName = currentThreadName()
        
        logSender.queue.async {
            logSender.send(level, tag: tag, msg: msgStr, thread: threadName, file: file, function: function, line: line, context: context)
        }
    }
    
    /// returns the current thread name
    private class func currentThreadName() -> String {
        if Thread.isMainThread {
            return ""
        } else {
            let threadName = Thread.current.name
            if let threadName = threadName, !threadName.isEmpty {
                return threadName
            } else {
                return String(format: "%p", Thread.current)
            }
        }
    }
}
