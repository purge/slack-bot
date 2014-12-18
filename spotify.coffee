#!/usr/bin/env coffee --nodejs --harmony

koa = require 'koa'
_ = require 'underscore'
Router = require('koa-router')
secret = require './secret.json'
Slack = require 'slack-node'
request = require 'request'
slack = new Slack(secret.slack_webhook_token, "theskiff")

app = koa()
app.use Router(app)

app.post '/spotify/:type', -->
  console.log @params
  console.log @request.query
  @body = 'Hello World'

app.listen(3000)
