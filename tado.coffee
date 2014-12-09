#!/usr/bin/env coffee

_ = require 'underscore'
secret = require './secret.json'
Slack = require 'slack-node'
request = require 'request'
slack = new Slack(secret.slack_webhook_token, "theskiff")
previous = {}
reached_target = false
emit = false

doit = ->
  request
    json: true,
    url: "https://my.tado.com/mobile/1.4/getCurrentState\?username\=theskiff\&password\=#{secret.tado_pass}"
  , (error, response, body) ->
    return unless body

    temp = Math.round(body.insideTemp * 10) / 10
    if !reached_target and temp >= body.setPointTemp
      reached_target = true

      slack.webhook
        channel: '#classic-tm'
        username: 'tado'
        text: "it's safe to come in - a balmy #{temp}C in Classic™"
      , (err, res) ->
        console.log res

    else
      reached_target = false

    if body.controlPhase != previous.controlPhase

      if emit
        slack.webhook
          channel: '#classic-tm'
          username: 'tado'
          text: "Changed status to #{body.controlPhase}. #{temp}°C in skiff classic™"
        , (err, res) ->
          console.log res

    previous = body
    emit = true


setInterval doit, 120 * 1000
doit()
