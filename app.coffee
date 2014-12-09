#!/usr/bin/env coffee

app = require('express')()
osa = require 'osa'

getForeground = (service, defaultHandle, done) ->
  all = Application('System Events').processes()
  (return p.name() if p.frontmost()) for p in all
  null

app.get( '/',
  (req, res) ->
    osa getForeground, (err, res2) ->
      res.send
        process_name: res2
        #is_tom_still_an_unmitigated_douche: true
)

server = app.listen 3000, ->
  d = server.address()
  console.log "Listening on #{d.address}:#{d.port}"
