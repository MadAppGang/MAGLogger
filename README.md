# MAGLogger

## About

MAGLogger is a library wich allows you to collect application logs and send them to server. It gathers such data as application`s session information and detailed log events to local storage. You are able to scpecify one of five log levels (verbose, debug, info, warning, error), event TAG (context) and payload for each log event. After amount of events has been reached particular value (which can be customized), library attempts to send gathered data to server. Also it attempts to send data to server on every application startup.

This library is distributed as two classes:
- MAGLogger - the main class to interact with library. It represents facade functions and prorerties to set library up and create log events;
- MAGBackendLogSender - class which allows to store log events locally and send them to server whenever it necessary. It conforms to MAGLogSender protocol.

If you want to implement your custom logging logic, you must implement your own log sender which must conform to MAGLogSender protocol, like MAGBackendLogSender class.

## Installation

### Swift Package Manager

For [Swift Package Manager](https://swift.org/package-manager/) add the following package to your Package.swift file:

``` Swift
.package(url: "https://github.com/MadAppGang/MAGLogger.git", .upToNextMajor(from: "1.0.0")),
```

<br/>

## Usage

Imprort MAGLogger module to be able to use it in your class.

``` Swift
import MAGLogger
```

At the the beginning of your AppDelegate:didFinishLaunchingWithOptions() configure the MAGLogger log sender:

``` Swift
let logger = MAGLogger.self
let logSender = MAGBackendLogSender(serverURL: URL(string: "https://....")!)
logger.logSender = logSender
```

You can also pass additional parameters to MAGBackendLogSender's initializer, to customize it`s behaviour. For example:
- appID and appSecret - to pass credetnitial for Basic-authentication
- sendToServerTimeout - to set custom server request timeout
- minAllowedThreshold - to set custom threshold for amount of log events before they will be sent to server

``` Swift
let logSender = MAGBackendLogSender(serverURL: URL, appID: String? = nil, appSecret: String? = nil, sendToServerTimeout: TimeInterval = 10, minAllowedThreshold: Int = 10)
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

MAGBackendLogSender sends gathered data to server in JSON format using HTTP POST requests. The structre of JSON to be sent to server looks like:

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
          "hostName":"yaroslavs-macbook-pro-2.local",
          "entries":[
              {
                "timestamp":1600932668.055263,
                "thread":"",
                "message":"hello1",
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
                "message":"hello2"
              }
            ]
        }]
    }
}
```
