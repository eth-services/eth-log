contract KindLogger {

    // A log with the source, a type, and a message
    // This will give you filterable logs on the contract's log page
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