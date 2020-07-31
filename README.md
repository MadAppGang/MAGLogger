# MAGLogger

Usage

Add that near the top of your AppDelegate.swift to be able to use MAGLogger in your whole project.

import MAGLogger

At the the beginning of your AppDelegate:didFinishLaunchingWithOptions() add the MAGLogger log sender:

let logger = MAGLogger.self
let logSender = MAGBackendLogSender(serverURL: URL(string: "https://....")!)
logger.logSender = alogSender

Now you can send logs:

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



