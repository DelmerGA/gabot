# Description:
#   organize the class.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot queue me for <reason> - puts someone on the student queue
#   hubot student queue - displays the current student queue
#   hubot unq(ueue)? me - removes student from queue


util   = require 'util'
_      = require 'underscore'
moment = require 'moment'
tfmt   = (time) -> moment(time).format 'MMM Do, h:mm:ss a'


module.exports = (robot) ->
  robot.brain.data.instructorQueue ?= []
  robot.brain.data.instructorQueuePops ?= []

  queueStudent = (name, reason) ->
    robot.brain.data.instructorQueue.push
      name: name
      queuedAt: new Date()
      reason: reason

  stringifyQueue = ->
    _.reduce robot.brain.data.instructorQueue, (reply, student) ->
      reply += "\n"
      reply += "#{student.name} at #{tfmt student.queuedAt} for #{student.reason}"
      reply
    , ""

  popStudent = ->
    robot.brain.data.instructorQueue.shift()

  robot.respond /q(ueue)? me$/i, (msg) ->
    msg.reply "usage: bot queue me for [reason]"

  robot.respond /q(ueue)? me(.+)/i, (msg) ->
    unless msg.match[2].match /^[ ]*for/i
      msg.reply "usage: bot queue me for [reason]"

  robot.respond /q(ueue)? me for (.+)/i, (msg) ->
    name = msg.message.user.mention_name || msg.message.user.name
    reason = msg.match[2]
    if _.any(robot.brain.data.instructorQueue, (student) -> student.name == name)
      msg.send "#{name} is already queued"
    else
      queueStudent name, reason
      msg.send "Current queue is: #{stringifyQueue()}"


  robot.respond /req(ueue)? me for (.+)/i, (msg) ->
    reason = msg.match[2]
    name = msg.message.user.mention_name || msg.message.user.name
    student = _.find(robot.brain.data.instructorQueue, (student) ->
      student.name == name)
    if student != undefined
      student.reason = reason
      msg.send "Current queue updated: #{stringifyQueue()}"
    else
      msg.reply "you weren't in the queue"


  robot.respond /unq(ueue)? me/i, (msg) ->
    name = msg.message.user.mention_name || msg.message.user.name
    if _.any(robot.brain.data.instructorQueue, (student) -> student.name == name)
      robot.brain.data.instructorQueue = _.filter robot.brain.data.instructorQueue, (student) ->
        student.name != name
      msg.reply "ok, you're removed from the queue."
    else
      msg.reply "you weren't in the queue."



  robot.respond /hop to @(\w+)/i, (msg) ->
    name = msg.match[1]
    student = {}
    robot.brain.data.instructorQueue = _.filter robot.brain.data.instructorQueue, (currStudent)->
      if currStudent.name == name
        student = currStudent
        false
      else
        true
  
    student.poppedAt = new Date()
    student.poppedBy = msg.message.user.mention_name || msg.message.user.name
    robot.brain.data.instructorQueuePops.push student
    msg.reply "go help @#{student.name} with #{student.reason}, queued at #{tfmt student.queuedAt}"

  robot.respond /(pop )?student( pop)?/i, (msg) ->
    return unless msg.match[1]? || msg.match[2]?
    if _.isEmpty robot.brain.data.instructorQueue
      msg.send "Student queue is empty"
    else
      student = popStudent()
      student.poppedAt = new Date()
      student.poppedBy = msg.message.user.mention_name || msg.message.user.name
      robot.brain.data.instructorQueuePops.push student
      msg.reply "go help @#{student.name} with #{student.reason}, queued at #{tfmt student.queuedAt}"

  

  robot.respond /student q(ueue)?/i, (msg) ->
    console.log msg
    console.log robot.brain.data.users
    msg.get /v1/users/list, (data)->
      console.log data
    #if _.isEmpty robot.brain.data.instructorQueue
    #  msg.send "Student queue is empty"
    #else
    #  msg.send stringifyQueue()

  robot.respond /empty q(ueue)?/i, (msg) ->
    instructors = ["RafiSofaer", "AlexNotov","MarkusGuehrs", "StuartJones",  "DelmerReed", "SpencerEldred", "TimGarcia", "TriptaGupta", "ColtSteel", "JackieHerrlin"]
    if instructors.indexOf(msg.message.user.mention_name) != -1
      robot.brain.data.instructorQueue = []
      msg.reply "cleared the queue"

  robot.respond /q(ueue)?[ .]length/i, (msg) ->
    _.tap robot.brain.data.instructorQueue.length, (length) ->
      msg.send "Current queue length is #{length} students."

  robot.router.get "/queue/pops", (req, res) ->
    res.setHeader 'Content-Type', 'text/html'
    _.each robot.brain.data.instructorQueuePops, (student) ->
      res.write "#{student.name} queued for #{student.reason} at #{tfmt student.queuedAt} popped at #{tfmt student.poppedAt} by #{student.poppedBy || 'nobody'}<br/>"
    res.end()
