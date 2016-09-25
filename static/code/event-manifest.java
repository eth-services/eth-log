contract EthLogInterface = {

    // Be sure to follow the signature exactly
    // Please submit any requests for new eth-log types at
    // http://github.com/eth-services/eth-log
    event LogMessage(address from, string m);
    event LogValue(address from, uint v);
    event LogAddress(address from, address a);

    event LogKindMessage(address from, string kind, string m);
    event LogKindValue(address from, string kind, uint v);
    event LogKindAddress(address from, string kind, address a);

    // Helpful functions for versioning and readability
    // Enables cleanly switching to a different event if
    // you want to stop logging
    function logMessage(string s) {
        LogMessage(msg.sender, s);
    }

    function logValue(uint v) {
        LogValue(msg.sender, v);
    }

    function logAddress(address a) {
        LogAddress(msg.sender, a);
    }

    function logKindMessage(string kind, string message) {
        LogKindMessage(msg.sender, kind, message);
    }

    function logKindValue(string kind, uint value) {
        LogKindValue(msg.sender, kind, value);
    }

    function logKindAddress(string kind, address a) {
        LogKindAddress(msg.sender, kind, a);
    }
}