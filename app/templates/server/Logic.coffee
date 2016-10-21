QPSettings      = require('./QPSettings')
QPUser          = require('./User')
QPCity          = require('./QPCity')
QPSensor        = require('./QPSensor')
QPToken         = require('./QPToken')
QPDevice        = require('./QPDevice')
QPProduct       = require('./QPProduct')

uuid            = require('node-uuid')

DB    = require('spincycle').DB
ResolveModule   = require('spincycle').ResolveModule


class Logic

  constructor: (@messageRouter)->
    console.log 'Logic  constructor called'

    #
    # This target can be reached through all methods that is added to SpinCycle in index.coffee (
    #
    @messageRouter.addTarget('createToken',          '<none>',       @onCreateToken)

    types =
      [
        { name: 'QPUser', module: QPUser}
        { name: 'QPCity', module: QPCity}
        { name: 'QPSensor', module: QPSensor}
        { name: 'QPToken', module: QPToken}
        { name: 'QPDevice', module: QPDevice}
        { name: 'QPProduct', module: QPProduct}
      ]
    @messageRouter.register(types).then () =>
      console.log 'Type models registered in SpinCycle'

      DB.getOrCreateObjectByRecord({id:17, type:'QPSettings'}).then (settings)=>
        console.log 'QPLogic found settings'
        console.dir settings
        @settings = settings
        @messageRouter.authMgr.setQpSettings(settings)
        settings.serialize()
        @messageRouter.open()

  onCreateToken: (msg) =>
    new QPToken({token:uuid.v4(), userRef:msg.user.id}).then (token) =>
      token.serialize()
      msg.user.tokens.push token
      msg.user.serialize()
      msg.replyFunc({status: 'SUCCESS', info: 'new token generated', payload: token.toClient()})

module.exports = Logic