somata = require 'somata'
polar = require 'somata-socketio'

Redis = require 'redis'
redis = Redis.createClient null, null

config = require './config'

client = new somata.Client()
ContractsService = client.bindRemote 'ethereum:contracts'
EventsService = client.bindRemote 'eth-log:events'

app = polar config.app

app.get '/', (req, res) ->
    res.render 'home'

['info','recipes'].map (slug) ->
    app.get '/:slug', (req, res) ->
        res.render req.params.slug

app.get '/logs/:contract_address.json', (req, res) ->
    {contract_address} = req.params
    EventsService 'findAllEvents', contract_address, (err, events) ->
        events.map (d) ->
            d.id_hash = d.event.blockNumber + '-' + d.event.logIndex

        res.json events

app.get '/logs/:contract_address', (req, res) ->
    {contract_address} = req.params
    # EventsService 'subscribeContract', address: contract_address, (err, resp) -> #....
    subscribeContract contract_address
    res.render 'log', {contract_address}

session_key = (address) ->
    "eth-log:active:contracts:#{address}"

address_from_key = (session_key) ->
    session_key.replace('eth-log:active:contracts:','')

subscribeContract = (address) ->
    key = session_key(address)
    redis.set key, true, (err, resp) ->
        redis.expire key, 10*60, (err, resp) ->

checkActiveContracts = (done) ->
    redis.keys "eth-log:active:contracts:*", (err, keys) ->
        console.log err, keys
        keys.map (k) ->
            address = address_from_key k
            EventsService 'checkContractEvents', address, (err, done) ->
        done null, keys

setInterval ->
    checkActiveContracts (err, done) ->
        console.log done
        console.log 'done'
, 2000

app.start()
