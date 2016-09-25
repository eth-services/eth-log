contract HelloLogger {

    // An event w/ function signature that is parsable by eth log
    // The logs will be available at
    // http://eth-log.io/logs/[this.address]
    event LogMessage(address from, string m);

    function createLog(string message) {

        // Log the sender and the message
        LogMessage(msg.sender, message);
    }

    // Hello
    function HelloLogger() {
        createLog("[HelloLogger.constructor] Hello world");
    }
}