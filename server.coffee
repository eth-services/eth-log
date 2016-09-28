somata = require 'somata'
polar = require 'somata-socketio'
h = require 'highlight.js'
fs = require 'fs'

Redis = require 'redis'
redis = Redis.createClient null, null

config = require './config'

client = new somata.Client()
ContractsService = client.bindRemote 'ethereum:contracts'
EventsService = client.bindRemote 'eth-log:events'

localsMiddleware = (req, res, next) ->
    Object.keys(config._locals).map (_l) ->
        res.locals[_l] = config._locals[_l]
    next()

highlightMiddleware = (req, res, next) ->
    res.locals.highlight = (filename) ->
        [filename, ext] = filename.split('.')
        source = fs.readFileSync "static/code/#{filename}.#{ext}"
        highlighted = h.highlight ext, source.toString()
        '<pre>\n' + highlighted.value.trim() + '</pre>'
    next()

app = polar config.app, middleware: [highlightMiddleware]

app.get '/', localsMiddleware, (req, res) ->
    res.render 'home'

['info','recipes', 'examples'].map (slug) ->
    app.get '/:slug', localsMiddleware, (req, res) ->
        res.render req.params.slug

app.get '/logs/:contract_address.json', (req, res) ->
    {contract_address} = req.params
    EventsService 'findAllEvents', contract_address, req.query, (err, events) ->
        events.map (d) ->
            d.id_hash = d.event.blockNumber + '-' + d.event.logIndex

        res.json events

app.get '/logs/:contract_address', localsMiddleware, (req, res) ->
    {contract_address} = req.params
    EventsService 'subscribeContract', address: contract_address, (err, resp) -> console.log err, resp
    subscribeContract contract_address

    context = {contract_address}
    if Object.keys(req.query).length
        context['_filter'] = req.query

    res.render 'log', context

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
