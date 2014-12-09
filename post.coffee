#!/usr/bin/env coffee
#
secret = require './secret.json'
Slack = require('slack-node')
hackerNews = require("node-hacker-news")()
slack = new Slack(secret.slack_webhook_token, "theskiff")

hackerNews.getHottestItems 5, (error, items) ->

  item = items[0]
  slack.webhook
    channel: "#programming",
    username: "procrastibot",
    text: "<#{item.url}|#{item.title}>"
  , (err, res) ->
    console.log(res)
