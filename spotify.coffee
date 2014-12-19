#!/usr/bin/env coffee --nodejs --harmony

koa = require 'koa'
async = require 'async'
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

say = (text) ->
  slack.webhook
    channel: '#skiff_spotify'
    username: 'spotify'
    text: text
  , (err) -> console.log "said #{text}"

say = (text) ->
  console.log "said #{text}"

add = (link) ->
  if played.indexOf(link) == -1 and queued.indexOf(link) == -1
    console.log "queuing #{link}"
    queued.push(link)
    return true
  false

app.post '/spotify/:type', -->
  body = yield parse @, limit: '1kb'
  trigger = body.text.split(" ")[0]
  @throw(404, "Trigger word incorrect") unless trigger == @params.type
  content = body.text.substr(@params.type.length+1)

  if matches = content.match(/<(.*)>/)
    say "Added" if add(matches[1])

  else
    #free text search
    request
      json: true,
      url: "https://api.spotify.com/v1/search?q=#{content}&type=track"
    , (error, response, body) ->
      if body.tracks.total > 0 and body.tracks.items[0]
        track = body.tracks.items[0]
        say("Added #{track.name}") if add(track.uri)

  @body = 'Ok'

app.listen(8080)

volDown = (cb, steps=5) ->
  console.log "setting volume"
  _.times steps, (i) ->
    _.delay (i) ->
      spotify.setVolume 100 - (i * 20)
      cb(null) if i == ( steps - 1 )
    , i * 200, i

track_length = 0

getTrack = (cb) ->
  spotify.getTrack (err, track) ->
    if err
      cb?(err)
    unless err
      say "Now playing: #{track.artist} - #{track.name}"
      cb?(null, track.duration)

checkStatus = ->
  spotify.getState (err, state) ->
    console.log "heartbeat - left #{track_length - state.position}"

    if state and queued.length and ((track_length - state.position <= 10 or state.state == 'paused') or track_length == 0)
      steps = []

      link = queued.shift()
      console.log "prepping to play #{link}"

      steps.push volDown
      steps.push (cb) ->
        console.log "playing track"
        spotify.playTrack link, ->
          track_length = 0
          cb()

      steps.push (cb) ->
        console.log "vol max"
        spotify.setVolume 100
        played.push link
        cb()

      steps.push (cb) ->
        _.delay ->
          getTrack (err, duration) ->
            console.log "new track duration is #{duration}"
            track_length = duration
            cb(err)
        , 1000

      async.series steps, (all) ->
        console.log "done steps"
        _.delay checkStatus, 5000

    else
      _.delay checkStatus, 5000


getTrack (err, duration) ->
  console.log "already playing track #{duration}"
  track_length = duration
  checkStatus()

