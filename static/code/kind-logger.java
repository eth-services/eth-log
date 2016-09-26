// A contract that logs messages with a filterable "kind"
contract KindLogger {

    // A log with the source, a type, and a message
    // This will yield filterable logs at http://eth-io/logs/[this.address]
    event LogKindMessage(address from, string kind, string m);

    // (useful helper function that will give you flexibility down the road)
    function createKindLog(string kind, string message) {
        LogKindMessage(msg.sender, kind, message);
    }

    // Some more interesting examples
    function createExampleKindLogs() {
        createKindLog('test', 'Hello');
        createKindLog('warning', 'Some kinds will be specially parsed');
        createKindLog('error [getItems]', 'No items');
    }
}