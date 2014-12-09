#!/usr/bin/env coffee

secret = require './secret.json'
Slack = require 'slack-node'
passport = require 'passport'
{Strategy} = require 'passport-slack'
app = require('express')()

passport.use(
  new Strategy
    clientID: secret.client_id
    clientSecret: secret.client_secret
  ,
    (accessToken, refreshToken, profile, done) ->
      console.log accessToken
      slack = new Slack(apiToken)

      slack.api "users.list", (err, res) ->
      console.log(res)
)

app.get('/auth/slack', passport.authorize('slack'))

app.get(
  '/auth/slack/callback',
  passport.authorize('slack', { failureRedirect: '/login' }),
  (req, res) -> res.redirect('/')
)

server = app.listen 3000, ->
  d = server.address()
  console.log "Listening on #{d.address}:#{d.port}"

