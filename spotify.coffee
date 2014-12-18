#!/usr/bin/env coffee --nodejs --harmony

koa = require 'koa'
_ = require 'underscore'
parse = require 'co-body'
Router = require('koa-router')
secret = require './secret.json'
Slack = require 'slack-node'
request = require 'request'
spotify = require('spotify-node-applescript')
slack = new Slack(secret.slack_webhook_token, "theskiff")

queued = []
played = []

app = koa()
app.use Router(app)

add = ->
  queued.push(link) unless played.indexOf(link) or queued.indexOf(link)

app.post '/spotify/:type', -->
  body = yield parse @, limit: '1kb'
  content = body.text.substr(@params.type.length+1)

  if matches = content.match(/<(.*)>/)
    add(matches[1])

  else
    #free text search
    request
      json: true,
      url: "https://api.spotify.com/v1/search?q=#{content}&type=track"
    , (error, response, body) ->
      if body.tracks.total > 0 and body.tracks.items[0].uri
        add(body.tracks.items[0].uri)

  @body = 'Ok'

app.listen(8080)

checkStatus = ->
  spotify.getState (err, state) ->
    return if !queued.length or state.state == 'playing' or (state.state == 'paused' and state.position != 0)

    link = queued.shift()
    spotify.playTrack link, ->
      played.push link

      _.delay
        spotify.getTrack (err, track) ->
          unless err
            slack.webhook
              channel: '#skiff_spotify'
              username: 'spotify'
              text: "#{track.artist} - #{track.name} is playing"
            , (err) -> console.log "done"
      ,100

setInterval checkStatus, 300

