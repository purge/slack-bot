#!/usr/bin/env coffee

_ = require 'underscore'
moment = require 'moment'
ical = require 'ical'
secret = require './secret.json'
Slack = require 'slack-node'
request = require 'request-then'
slack = require('slack-notify')(secret.slack_events_url)
$q = require 'q'

calendars = [
  "https://www.google.com/calendar/ical/theskiff.org_po6n14afi6ffp6p6jdnvnp4520@group.calendar.google.com/public/basic.ics"
  "https://www.google.com/calendar/ical/theskiff.org_4ivni1lkm1i08on49mbbip7ffs%40group.calendar.google.com/public/basic.ics"
  "https://www.google.com/calendar/ical/hello%40theskiff.org/public/basic.ics"
]

now = moment()
today = []
all = []

_.each calendars, (url) ->

  all.push request(uri: url).then (resp) ->
    if resp.statusCode != 200
      throw {error: "Error retrieving url with code #{resp.statusCode}" }

    ics = ical.parseICS(resp.body)
    _.each ics, (event) ->
      if event.type == 'VEVENT'
        start = moment(event.start)
        if start.isSame(now, 'day')

          today.push
            time:start.format("HH:mm")
            summary: event.summary

defer = $q.all(all)

defer.done ->
  if today.length
    byTime = _.sortBy today, (e) -> e.time
    asAttachment = _.flatten _.map byTime, (e) ->
      [
        value: e.time,
        short: true
      ,
        value: e.summary,
        short: true
      ]

    slack.send
      channel: "#events"
      username: "eventbot"
      text: 'Today at The Skiff',
      attachments: [
        {
          fallback: 'Fallback...',
          fields: asAttachment
        }
      ]
