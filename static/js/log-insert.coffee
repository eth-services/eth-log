React = require 'react'
ReactDOM = require 'react-dom'
moment = require 'moment'

{Txid, ContractMixin, LogItem} = require './common'
KefirCollection = require 'kefir-collection'
fetch$ = require 'kefir-fetch'

somata = require './somata-stream'

Dispatcher =
    getContractLogs: (address) ->
        fetch$ 'get', "/logs/#{address}.json"
    pending_transactions$: KefirCollection([], id_key: 'hash')
    contract_logs$: KefirCollection([], id_key: 'id_hash')


LogInsert = React.createClass
    mixins: [ContractMixin]

    getInitialState: ->
        logs: []
        loading: true
        transactions: []
        block_number: null

    componentDidMount: ->
        @contract$ = Dispatcher.getContractLogs(window.contract_address)
        @contract$.onValue @foundLogs
        @transactions$ = Dispatcher.pending_transactions$
        @transactions$.onValue @setTransactions
        @logs$ = Dispatcher.contract_logs$
        @logs$.onValue @handleLogs

    componentWillUnmount: ->
        @contract$.offValue @foundContract
        @transactions$.offValue @setTransactions
        @logs$.offValue @handleNewLog

    setTransactions: (transactions) ->
        @setState {transactions}

    foundLogs: (logs) ->
        logs.map (l) -> l.id_hash = l.event.blockNumber + '-' + l.logIndex
        @setState loading: false
        Dispatcher.contract_logs$.setItems logs

    handleLogs: (logs) ->
        @setState {logs}, =>
            @fixScroll()

    render: ->
        console.log @state
        <div className='log-insert'>
            <div>
                {if @state.loading
                    <div className='loading'>loading...</div>
                else
                    <div>
                        {@renderActivity()}
                    </div>
                }
            </div>
            <div className='col half'>
                <h3>Pending Transactions</h3>
                {@state.transactions.map (t, i) ->
                    <div><Txid txid={t.hash} key=i /></div>
                }
            </div>
        </div>

    renderActivity: ->
        <div className='logs' id='logs'>
            {@state.logs.map @renderLog}
        </div>

    renderLog: (l, i) ->
        <LogItem l=l key=i />

    fixScroll: ->
        $logs = document.getElementById('logs')
        $logs?.scrollTop = $logs?.scrollHeight

module.exports = LogInsert

somata.subscribe('ethereum:contracts', "contracts:#{window.contract_address}:pending_tx").onValue (data) ->
    if data?
        Dispatcher.pending_transactions$.createItem data
        window.block = data.blockNumber

somata.subscribe('eth-log:events', "contracts:#{window.contract_address}:events").onValue (data) ->
    data.id_hash = data.event.blockNumber + '-' + (d.event.logIndex + 1)
    console.log data
    console.log 'lkjsdlfkjsldkfjsldkfjlsdkjflsdkfj'
    if !data.event.logIndex?
        console.log 'BROKENENNENENENE', data.event.blockNumber + '-' + (data.event.logIndex + 1)
    Dispatcher.contract_logs$.updateItem data.id_hash, data

somata.subscribe('eth-log:events', "contracts:#{window.contract_address}:all_events").onValue (data) ->
    data = data.map (d) ->
        if !d.event.logIndex?
            console.log 'its here'
            console.log 'BROKENENNENENENE', d.event.blockNumber + '-' + (d.event.logIndex + 1)
        d.id_hash = d.event.blockNumber + '-' + (d.event.logIndex + 1)
        return d
    Dispatcher.contract_logs$.setItems data

somata.subscribe('ethereum:contracts', "all_blocks").onValue (data) ->
    console.log 'new block', data
    text = document.createTextNode("New block, ##{data.number}")
    document.getElementById("block_counter").appendChild(text)

ReactDOM.render(<LogInsert />, document.getElementById('insert'))

