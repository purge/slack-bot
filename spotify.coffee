#!/usr/bin/env coffee --nodejs --harmony

koa = require 'koa'
_ = require 'underscore'
Router = require('koa-router')
secret = require './secret.json'
Slack = require 'slack-node'
request = require 'request'
slack = new Slack(secret.slack_webhook_token, "theskiff")

parse = require 'co-body'
app = koa()
app.use Router(app)

app.post '/spotify/:type', -->
  body = yield parse @, limit: '1kb'
  console.log body
  @body = 'Hello World'

app.listen(8080)
