uuid            = require('node-uuid')
defer           = require('node-promise').defer
util            = require('util')
OStore          = require('spincycle').OStore
DB              = require('spincycle').DB
QPUser        = require('./server//QPUser')
ClientEndpoints = require('spincycle').ClientEndpoints
#EmailAuth       = require('./server/EmailAuthentication')
passport        = require('passport')
Cookies         = require('cookies')
session         = require('express-session')
redis           = require('redis')
debug = process.env["DEBUG"]

# verifies authentication keys in incoming messages and finds the user for them
class AuthenticationManager

  constructor: (@app)->
    console.log '---------------------------------------------------------- AuthMgr constructor'
    @admins = ['psvensson@gmail.com']
    @anonymousUsers = []
    ClientEndpoints.onDisconnect(@onDisconnect)
    @sessions = []
    #@eauth = new EmailAuth()

    passport.serializeUser = (user, done) ->
      if user
        console.log 'passport serializeuser called'
        console.dir user
        localuser =
          providerId : user.id
          displayName: user.displayName
          name: user.name
          gender: user.gender
          profileUrl: user.profileUrl || user._json?.link
          picture: user._json?.picture
          provider: user.provider
          email: user._json?.email

        new QPUser(localuser).then (user) =>
          user.serialize()
          done(null, user)

    passport.deserializeUser (user, done) ->
      DB.get('QPUser', [user.id]).then (dbuser) ->
        done(null, dbuser[0])

  getContent: (url) =>
    q = defer()
    #console.log 'getContent called for '+url
    lib = if url.startsWith('https') then require('https') else require('http')
    request = lib.get url,(response) =>
      # handle http errors
      #console.log 'got response '+response
      if (response.statusCode < 200 or response.statusCode > 299)
        console.dir response.headers
        q.reject(new Error('Failed to load page, status code: ' + response.statusCode))
      else
        # temporary data holder
        body = []
        # on every content chunk, push it to the data array
        response.on('data', (chunk) =>
          #console.log 'chunking '+chunk
          body.push(chunk))
        # we are done, resolve promise with those joined chunks
        response.on('end', () =>
          #console.log 'resolving'
          q.resolve(body.join('')))

    # handle connection errors of the request
    request.on('error', (err) =>
      console.log 'getContent got error '+err
      q.reject(err))
    q

  setQpSettings: (@settings) =>
    console.log 'authmgr.setGeSettings qpsettings are'
    console.dir @settings

  setup: (@messageRouter) =>
    console.log '---------------------------------------------------------- AuthMgr setup messageRouter = '+@messageRouter

    @activeUsers = []
    @replyCallbacks = []

    @messageRouter.addTarget('getCurrentUser',        '<none>',         @onGetUser)
    @messageRouter.addTarget('getUserFromSessionId',  'sessionId',      @onGetUserFromSessionId)
    @messageRouter.addTarget('logoutUser',            'sessionId',      @onLogoutUser)
    @messageRouter.addTarget('login',                 'access_token',        @onLogin)

  onRegisterAuthCallback: (msg) =>
    @replyCallbacks[msg.uuid] = msg

  onGetUser: (msg) =>
    console.log 'onGetUser called'
    user = @activeUsers[msg.sessionId]
    if user
      OStore.getObject(user.id, user.type).then (userobj) =>
        muuid = msg.uuid
        if muuid
          cbmsg = @replyCallbacks[muuid]
          if cbmsg
            delete @replyCallbacks[muuid]
            cbmsg.replyFunc({user: userobj.toClient()})
        tc = userobj.toClient()
        tc.admin = userobj.isAdmin
        tc.sessionId = userobj.sid
        console.log '========================================= getUser return '+JSON.stringify(tc)
        if userobj then msg.replyFunc({status: 'SUCCESS', info: 'user profile', payload: tc})
    else
      userobj = @anonymousUsers[msg.client]
      if userobj
        tc = userobj.toClient()
        tc.admin = userobj.isAdmin
        tc.sessionId = userobj.sid
        console.log '========================================= getUser return anonymous '+JSON.stringify(tc)
        msg.replyFunc({status: 'SUCCESS', info: 'user profile', payload: tc})
      else
        msg.replyFunc({status: 'SUCCESS', info: 'null user profile', payload: {}})

  onGetUserFromSessionId: (msg) =>
    console.log 'onGetUserFromSessionId called'
    if msg.sessionId
      obj = @activeUsers[msg.sessionId]
      if obj
        console.log 'found user in activeUsers cache'
        @sendUserFromSessionId(msg, obj.id)
      else
        DB.findMany('QPUser', 'sessionId', msg.sessionId).then (urecords) =>
          if urecords and urecords[0]
            console.log 'found user for sessionid in DB'
            @sendUserFromSessionId(msg, urecords[0].id)
          else
            console.log 'could not find user for sessionId '+msg.sessionId
            #console.dir @activeUsers
            msg.replyFunc({status: 'FAILURE', info: 'onGetUserFromSessionId: no user for sessionId', payload: null})
    else
      msg.replyFunc({status: 'FAILURE', info: 'onGetUserFromSessionId: missing parameter', payload: null})

  sendUserFromSessionId:(msg, uid)=>
    console.log 'sendUserFromSessionId resolving user with id '+uid
    DB.getFromStoreOrDB('QPUser', uid).then (userobj)=>
      console.log 'found user'
      tc = userobj.toClient()
      tc.admin = userobj.isAdmin
      console.log JSON.stringify tc
      msg.replyFunc({status: 'SUCCESS', info: 'user profile', payload: tc})

  """
  createUser: (localuser, msg) =>
    DB.byProviderId('Player', localuser.providerId).then (dbuser) =>
      console.log 'on authenticate query for got back user '+dbuser
      if debug then console.dir dbuser
      if dbuser
        localuser = dbuser
        console.log '-- Found existing user with id '+localuser.id+' and provider id '+localuser.providerId
      else
        console.log '-- Found no existing user with provider id '+localuser.providerId
      localuser.lastLogin = new Date()+""
      localuser.type = 'Player'
      OStore.getOrCreateObjectFromRecord(localuser).then (userobj) =>
        @finishLogin(userobj, msg)
  """

  onLogin: (msg) =>
    console.log 'Login called. access_token = '+msg.access_token
    if msg.access_token
# verify userinfo
      @getContent('https://qp1.eu.auth0.com/userinfo/?access_token='+msg.access_token).then (_uprofile) =>
        uprofile = JSON.parse(_uprofile)
        console.log 'auth0 userinfo returns'
        console.dir uprofile
        # find user by email or create new and persist
        DB.findMany('QPUser', 'email', uprofile.email).then (urecords) =>
          console.log 'result of finding existing user with email '+uprofile.email+' is '+urecords
          console.dir urecords
          if urecords and urecords[0]
            DB.getFromStoreOrDB('QPUser', urecords[0].id).then (userobj)=>
              @finishLogin(userobj, uprofile, msg)
          else
            new QPUser(uprofile).then (newuserobj) =>
              @finishLogin(newuserobj, uprofile, msg)
    else
      console.log 'missing access_token!!!'
      console.dir msg
      msg.replyFunc({status: 'FAILURE', info: 'onLogin: missing parameter access_token', payload: null})

  decorateUserWith: (userobj, uprofile)=>
    userobj.cdata = uprofile.cdata or {}
    userobj.displayname = uprofile.displayName or ' '
    userobj.name = uprofile.displayName || uprofile.name
    userobj.profileUrl = uprofile.profileUrl or ' '
    userobj.picture = uprofile.picture
    userobj.email = uprofile.email
    return userobj

  finishLogin: (_userobj, uprofile, msg) =>
    userobj = @decorateUserWith(_userobj, uprofile)
    userobj.nologins++
    userobj.lastLogin = Date.now()
    oldu = @activeUsers[sid]
    if oldu
      userobj.sessionId = oldu.sid
      sid = oldu.sid
    else
      sid = uuid.v4()
      userobj.sessionId = sid
    userobj.serialize().then () =>
      console.log '------------------------------------------------------------------ finishLogin called for user '+userobj.email+' with picture '+userobj.picture+' and sessionId '+userobj.sessionId
      #console.dir userobj
      @activeUsers[sid] = userobj
      toclient = userobj.toClient()
      toclient.sid = sid
      toclient.admin = true if userobj.isAdmin
      if @allowUser(userobj)
        console.log 'user logged in successfully: '+toclient.email
        @activeUsers[msg.sessionId] = userobj
        console.log 'admin = '+toclient.admin
        console.dir toclient
        msg.replyFunc({status: 'SUCCESS', info: 'user profile', payload: toclient})
      else
        console.log 'user not allowed to login: '+toclient.email
        msg.replyFunc({status: 'FAILURE', info: 'user not allowed to log in (email address or domain restrictions)', payload: toclient.email})

  allowUser: (userobj) =>
#console.log 'allowUser users are '+@settings.users
    rv = (@settings.users.indexOf(userobj.email) > -1) or (@settings.admins.indexOf(userobj.email) > -1)
    if not rv
      domains = @settings.domains.split(',')
      domains.forEach (domain) ->
        if userobj.email.indexOf(domain) > -1 then rv = true
    #console.log 'allowuser for name '+userobj.name+' email '+userobj.email+' returns '+rv
    if @settings.allowAnonymous then rv = true
    return rv

  isUserAdmin: (userobj) =>
    #console.dir(userobj)
    rv = @settings.admins.indexOf(userobj.email) > -1
    console.log 'isUserAdmin user email is '+userobj.email+' admins are '+@settings.admins+' rv = '+rv
    return rv

  onLogoutUser: (msg) =>
    sid = msg.sessionId
    if sid
      delete @activeUsers[msg.sessionId]
      console.log 'removing user session for sid '+sid
      msg.replyFunc({status: 'SUCCESS', info: 'user logged out', payload: sid})

  setPublicGame: (@publicgame)=>

  decorateMessageWithUser: (message) =>
    console.log 'decorateMessageWithUser for '+message.sessionId
    q = defer()
    if message.sessionId
      user = @activeUsers[message.sessionId]
      if user
        console.log 'decorateMessageWithUser found active user '+user.name
        message.user = user
        q.resolve(message)
      else
        DB.findMany('QPUser', 'sessionId', message.sessionId).then (urecords) =>
          if urecords and urecords[0]
            DB.getFromStoreOrDB('QPUser', urecords[0].id).then (userobj)=>
              message.user = userobj
              @activeUsers[message.sessionId] = userobj
              userobj.admin = true if userobj.email in @admins
              console.log 'decorateMessageWithUser finding existing user '+userobj.name+' for sessionId '+message.sessionId
              q.resolve(message)
          else
            @getAnonymousUser(message).then (pl)=>
              q.resolve(message)
    else
      @getAnonymousUser(message).then (pl)=>
        q.resolve(message)
    return q

  getAnonymousUser: (message) =>
    p = defer()
    pl = @anonymousUsers[message.client]
    if pl
      message.user = pl
      p.resolve(message)
    else
      console.log '* no existing player for client '+message.client
      new QPUser(
        name: 'Anonymous '+uuid.v4()
      ).then((pl)=>
        console.log 'decorating message with newly created player '+pl.id+' on client '+message.client
        pl.sid = uuid.v4()
        console.log 'setting user sessionId to '+pl.sid
        pl.isAnonymous = yes
        message.user = pl
        OStore.storeObject(pl)
        @activeUsers[pl.sid] = pl
        @anonymousUsers[message.client] = pl
        console.log ClientEndpoints.endpoints
        p.resolve(message)
      )
    return p

  onDisconnect: (adr) =>
    player = @anonymousUsers[adr]
    # if player anonymous
    if player and player.isAnonymous
      console.log 'onDisconnect got player '+player.name+' from disconnecting address '+adr
      # Get all player characters
      #player.delete()
      #DB.remove player, () => OStore.removeObject(player)
      # delete player
      delete @anonymousUsers[adr]
#delete @activeUsers[player.sid]

  canUserReadFromThisObject: (obj, user) =>
    """
    #console.log 'canPlayerReadFromThisObject called obj = '+obj+' player = '+player.id+' obj.public = '+obj.public
    #console.dir obj
    match = (obj.createdBy is player.id) or obj.type == 'Thing' or obj.type == 'Game' or (obj.type == 'Team' and player.teamRef == obj.id)
    #if not match then match = obj.createdBy is player.id
    #console.log 'canPlayerReadFromThisObject match = '+match
    if not match then match = player.isAdmin
    return match
    """
    rv = @allowUser(user)
    rv = obj.id == user.id
    rv = obj.userRef == user.id
    if @isUserAdmin(user) then rv = true
    return rv

  canUserWriteToThisObject: (obj, user) =>
    """
    match = obj.createdBy  is player.id
    #if not match then match = obj.createdBy is player.id
    #console.log 'canPlayerWriteToThisObject match = '+match
    if not match then match = player.isAdmin
    return match
    """
    rv = obj.id == user.id
    rv = obj.userRef == user.id
    if @isUserAdmin(user) then rv = true
    return rv

# When a user sends a '_create'+<object_type> message, this method gets called to allow or disallow creating of the object
  canUserCreateThisObject: (type, user) =>
#user.isAdmin # same here
    if @isUserAdmin(user) then rv = true
    return rv

# When a user sends a '_create'+<object_type> message, this method gets called to allow or disallow creating of the object
  canUserListTheseObjects: (type, user) =>
#user.isAdmin

    if @isUserAdmin(user) then rv = true
    return rv

module.exports = AuthenticationManager