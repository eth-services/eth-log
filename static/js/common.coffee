React = require 'react'
moment = require 'moment-timezone'
qs = require 'querystring'

Transfer = React.createClass

    render: ->
        <div className='transfer'>
            &rarr; {@props.to}
        </div>

Txid = ({txid}) ->
    render: ->
        if @props.type
            base_url = encodeURIComponent('localhost:3534/#/')
            <a className='txid' href="http://localhost:1188/pending/#{txid}?redirect=#{base_url}#{@props.type}/[t.contractAddress]" target="_newtab">{txid}</a>

        else
            <a className='txid' href="http://localhost:1188/pending/#{txid}" target="_newtab">{txid}</a>

ContractMixin =

    renderField: (f) ->
        <div className='field' key=f >
            <label>{f}</label>
            <div className='value'>{@state.contract?[f]}</div>
        </div>

    renderSubcontractField: (model, f) ->
        <div className='model-field' key=f >
            <h5>{f}</h5>
            <div className=''>{model[f]}</div>
        </div>

LogItem = React.createClass
    
    doQuery: (query) -> ->
        console.log window.location
        {origin, pathname} = window.location
        window.location = origin + pathname + '?' + qs.encode(query)

    render: ->
        {l} = @props
        <div className='log' key=l.address >
            {if l.kind then <div className="tag #{l.kind}" onClick={@doQuery({kind: l.kind})} >{l.kind}</div>}
            <div className='message'>{l.message}</div>
            <div className='metadata'>
                <a href="http://etherscan.io/tx/#{l.event.transactionHash}" target="_newtab"><div className='timestamp'>{moment(l.event.block.timestamp*1000).fromNow() + ' from'}</div></a>
                {if l.address then <div className='address' onClick={@doQuery({address: l.address})}>{l.address}</div>}
            </div>
        </div>

module.exports = {
    Transfer
    Txid
    ContractMixin
    LogItem
}