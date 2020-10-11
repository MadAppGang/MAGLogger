# MAGLogger
<p align="left"><a href="https://swift.org" target="_blank"><img src="https://img.shields.io/badge/Language-Swift%203,%204%20&%205-orange.svg" alt="Language Swift 2, 3, 4 & 5"></a> <a href="https://circleci.com/gh/SwiftyBeaver/SwiftyBeaver" target="_blank"><img src="https://travis-ci.org/MadAppGang/MAGLogger.svg?branch=master" alt="CircleCI"/> <a href="https://github.com/apple/swift-package-manager" target="_blank"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="Swift Package Manager compatible"/></a><br/><p>

## About

<em>MAGLogger</em> is a library wich allows you to collect application logs and send them to server. It gathers such data as application`s session information and detailed log events to local storage. You are able to specify one of five log levels: verbose, debug, info, warning, error, event TAG, context and payload for each log event. After the amount of events has reached particular value (which can be customized), library attempts to send gathered data to the server. Also it attempts to send data to the server on every application startup.

This library is distributed as two classes:
- <em>MAGLogger</em> - the main class to interact with library. It represents facade functions and prorerties to set library up and create log events;
- <em>MAGBackendLogSender</em> - class which allows to store log events locally and send them to the server whenever it is necessary. It conforms to <em>MAGLogSender</em> protocol.

If you want to implement your custom logging logic, you should implement your own log sender which would conform to <em>MAGLogSender</em> protocol, like <em>MAGBackendLogSender</em> class.

## Installation

### Swift Package Manager

For [Swift Package Manager](https://swift.org/package-manager/) add the following package to your Package.swift file:

``` Swift
.package(url: "https://github.com/MadAppGang/MAGLogger.git", .upToNextMajor(from: "1.0.0")),
```

<br/>

## Usage

Imprort <em>MAGLogger</em> module to be able to use it in your class.

``` Swift
import MAGLogger
```

At the the beginning of your AppDelegate:didFinishLaunchingWithOptions() configure the <em>MAGLogger</em> log sender:

``` Swift
let logger = MAGLogger.self
let logSender = MAGBackendLogSender(serverURL: URL(string: "https://....")!)
logger.logSender = logSender
```

You can also pass additional parameters to <em>MAGBackendLogSender</em>'s initializer, to customize it`s behaviour. For example:
- appID and appSecret - to pass credentials for Basic-authentication
- sendToServerTimeout - to set custom server request timeout
- minAllowedThreshold - to set custom threshold for amount of log events before they will be sent to server

``` Swift
let logSender = MAGBackendLogSender(serverURL: URL(string: "https://...")!, appID: "...", appSecret: "...", sendToServerTimeout: 30, minAllowedThreshold: 50)
```

Now you can send logs:

``` Swift
// Now let’s log!
logger.verbose("My_TAG", "not so important")  // prio 1, VERBOSE
logger.debug("My_TAG", "something to debug")  // prio 2, DEBUG
logger.info("My_TAG", "a nice information")   // prio 3, INFO
logger.warning("My_TAG", "oh no, that won’t be good")  // prio 4, WARNING
logger.error("My_TAG", "ouch, an error did occur!")  // prio 5, ERROR


// log anything!
logger.verbose("My_TAG", 123)
logger.info("My_TAG", -123.45678)
logger.warning("My_TAG", Date())
logger.error("My_TAG", ["I", "like", "logs!"])
logger.error("My_TAG", ["name": "Mr Beaver", "address": "7 Beaver Lodge"])

// optionally add context to a log message
logger.debug("My_TAG", "age", context: 123)  // "DEBUG: age 123"
logger.info("My_TAG", "my data", context: [1, "a", 2]) // "INFO: my data [1, \"a\", 2]"
```

## Data format

<em>MAGBackendLogSender</em> sends gathered data to server in JSON format using HTTP POST requests. The structre of JSON sent to server looks like:

``` JSON
{
  "payload": {
      "sessions":[{
          "deviceName":"iPhone 8 Plus",
          "osVersion":"14.0.0",
          "appVersion":"1.0",
          "os":"iOS",
          "timestamp":1600932660.864331,
          "deviceModel":"x86_64",
          "sessionID":"2E26CFD3-8CFF-45EA-8C50-1C50DE45D36D",
          "appBuild":1,
          "hostName":"users-macbook-pro-2.local",
          "entries":[
              {
                "timestamp":1600932668.055263,
                "thread":"",
                "message":"test log message",
                "tag":"",
                "line":20,
                "function":"actionTest(_:)",
                "level":1,
                "file":"ViewController.swift"
              }, {
                "thread":"",
                "function":"actionTest(_:)",
                "level":1,
                "tag":"",
                "line":20,
                "timestamp":1600932668.671736,
                "file":"ViewController.swift",
                "message":"1265"
              }
            ]
        }]
    }
}
```
