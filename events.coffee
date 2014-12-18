#!/usr/bin/env coffee

_ = require 'underscore'
moment = require 'moment'
ical = require 'ical'
secret = require './secret.json'
Slack = require 'slack-node'
request = require 'request-then'
slack = require('slack-notify')(secret.slack_events_url)
RRule = require('rrule').RRule

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
      #console.log event if event.summary == 'DotBrighton'
      has_recurrance = false
      if event.type == 'VEVENT'
        if event.rrule
          opts = _.omit event.rrule.options, ['bynmonthday','bynweekday']
          rule = new RRule opts

          has_recurrance = rule.between(
            now.clone().startOf('day').toDate(),
            now.clone().endOf('day').toDate(),
          ).length
          console.log now.clone().startOf('day').toDate(),
          console.log now.clone().endOf('day').toDate(),
          console.log has_recurrance

        start = moment(event.start)
        if has_recurrance or start.isSame(now, 'day')

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
    console.log asAttachment

    #slack.send
      #channel: "#events"
      #username: "eventbot"
      #text: 'Today at The Skiff',
      #attachments: [
        #{
          #fallback: 'Fallback...',
          #fields: asAttachment
        #}
      #]
