_ = require 'underscore'
async = require 'async'
somata = require 'somata'
Web3 = require 'web3'
SolidityCoder = require("web3/lib/solidity/coder.js")

config = require '../config'

client = new somata.Client()

LoginService = client.bindRemote 'eth-login:events'

# Start web3
web3 = new Web3()
web3.setProvider(new web3.providers.HttpProvider("http://#{config.eth_ip}:8545"))

processEvent = (e) ->
    console.log "i will process", e

    # logMessage
    if e.topics[0] == '0xdf2f43000ad262ff927c671ed83129f9054af075e5d3add03a2ba7116e719a51'
        _data = SolidityCoder.decodeParams(["address", "string"], e.data.replace("0x",""))
        [address,message] = _data
        return {address, message, event: e}

    # logAddress
    else if e.topics[0] == '0x0959b33a2844b323a7a32552394b5754301f6403e59f952dfbf3f1e1982e8fdf'
        _data = SolidityCoder.decodeParams(["address", "address"], e.data.replace("0x",""))
        [address,message] = _data
        return {address, message, event: e}

    # logValue
    else if e.topics[0] == '0x1aea1368c4867b24356b44a7a33da7e5fd702bb1ef777d0e417d09c8c0717f3c'
        _data = SolidityCoder.decodeParams(["address", "uint"], e.data.replace("0x",""))
        [address,message] = _data
        return {address, message, event: e}

    # logKindMessage
    else if e.topics[0] == '0x347b697c4de855faba213a72bdcb60babafd496beec16795e2db00945d8768d8'
        _data = SolidityCoder.decodeParams(["address", "string", "string"], e.data.replace("0x",""))
        [address, kind, message] = _data
        return {address, kind, message, event: e}

    # logKindAddress
    else if e.topics[0] == '0xc1f04f43c818c2a53589a8c8bd7d7b107bc70b01093b289cf30a8a565b2ddfa5'
        _data = SolidityCoder.decodeParams(["address", "string", "address"], e.data.replace("0x",""))
        [address, kind, message] = _data
        return {address, kind, message, event: e}

    # logKindValue
    else if e.topics[0] == '0x66cd17a312b6d0cea4030b9206758d0eb98d58f06e0dfb7b846d2ebd1f37e8a6'
        _data = SolidityCoder.decodeParams(["address", "string", "uint"], e.data.replace("0x",""))
        [address, kind, message] = _data
        return {address, kind, message, event: e}

    else return null

Subscriptions = []

attachBlock = (i, cb) ->
    web3.eth.getBlock i.blockHash, (err, block) ->
        i.block = block
        cb null, i

subscribeContract = (c) ->
    console.log 'Ill subscribe this thing', c.address
    if c.address in Subscriptions
        return console.log 'Contract is already subscribed'
    else
        Subscriptions.push c.address
    web3.eth.getBlockNumber (err, block_no) ->
        contract_filter = web3.eth.filter({fromBlock:block_no, toBlock: 'latest', address: c.address})
        contract_filter.watch (err, result) ->
            attachBlock result, (err, result) ->

                _data = processEvent result
                async.map result, attachBlock, (err, result) ->

                    if _data?
                        console.log result, _data
                        console.log "New event", result
                        console.log "Decoded to", _data
                        service.publish "events:#{c.address}", _data
                        service.publish "contracts:#{c.address}:events", _data

findAllEvents = (address, query, cb) ->
    filter = web3.eth.filter({fromBlock:0, toBlock: 'latest', address})
    console.log address
    # Fetches and decodes stream of events
    filter.get (err, result) ->
        console.log err, result
        return console.log err, address if err?

        async.map result, attachBlock, (err, result) ->
            data = result.map (r) ->
                processEvent r
            data = data.filter (d) ->
                result = true
                Object.keys(query).map (q_k) ->
                    if d[q_k] != query[q_k]
                        result = false

                return result

            console.log query
            data = _.compact data

            cb null, data

checkContractEvents = (address, cb) ->
    return cb null, true
    filter = web3.eth.filter({fromBlock:0, toBlock: 'latest', address})
    filter.get (err, result) ->
        console.log err, result
        return console.log err, address if err?

        async.map result, attachBlock, (err, result) ->
            data = result.map (r) ->
                processEvent r
            data = _.compact data
            console.log data.map (d) -> d.event.blockNumber + '-' + d.event.logIndex

            # service.publish "contracts:#{address}:all_events", data

setInterval ->
    console.log 'subscriptions are', Subscriptions
, 2000

service = new somata.Service 'eth-log:events', {
    findAllEvents
    checkContractEvents
    subscribeContract
}