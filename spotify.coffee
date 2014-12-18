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

add = (link) ->
  if played.indexOf(link) == -1 and queued.indexOf(link) == -1
    console.log "queuing #{link}"
    queued.push(link)
    return true
  return false

app.post '/spotify/:type', -->
  body = yield parse @, limit: '1kb'
  trigger = body.text.split(" ")[0]
  @throw(404, "Trigger word incorrect") unless trigger == @params.type
  content = body.text.substr(@params.type.length+1)

  if matches = content.match(/<(.*)>/)
    if add(matches[1])
      slack.webhook
        channel: '#skiff_spotify'
        username: 'spotify'
        text: "Added!"
      , (err) -> console.log "added via link"

  else
    #free text search
    request
      json: true,
      url: "https://api.spotify.com/v1/search?q=#{content}&type=track"
    , (error, response, body) ->
      if body.tracks.total > 0 and body.tracks.items[0]
        track = body.tracks.items[0]
        if add(track.uri)
          slack.webhook
            channel: '#skiff_spotify'
            username: 'spotify'
            text: "Added #{track.name}"
          , (err) -> console.log "added via search"

  @body = 'Ok'

app.listen(8080)

cur_length = 0

volDown = ->
  _.times 5, (i) ->
    _.delay (i) ->
      console.log "set volume #{100 - (i * 20)}"
      spotify.setVolume 100 - (i * 20)
    , i * 200, i

getTrack = ->
  spotify.getTrack (err, track) ->
    unless err
      cur_length = track.duration
      slack.webhook
        channel: '#skiff_spotify'
        username: 'spotify'
        text: "Now playing: #{track.artist} - #{track.name}"
      , (err) -> console.log "track name delviered"

in_change = false

checkStatus = ->
  spotify.getState (err, state) ->
    return unless state and queued.length

    if !in_change and cur_length - state.position < 10
      link = queued.shift()
      console.log "going to play #{link} in 5 seconds"
      in_change = true
      volDown()

      _.delay ->
        spotify.playTrack link, ->
          spotify.setVolume 100
          in_change = false
          played.push link
          _.delay getTrack, 100
          _.delay ->
            in_change = false
          , 1000
      , 800

getTrack()
setInterval checkStatus, 500

