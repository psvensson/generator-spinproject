
express = require('express')
app = express()
bodyParser = require('body-parser');
server          = require("http").createServer(app)
port =    process.env.PORT or 6006

#dbUrl =   process.env['RETHINK_DB']
dbUrl = null

_log = console.log
console.log = (msg)->
  ts = new Date()+""
  _log ts+' - '+msg


server.listen port, ->
  console.log "Server listening at port %d", port

app.use(bodyParser.urlencoded({
  extended: true
}))
app.use(bodyParser.json())

app.use (req, res, next) ->
  res.header 'Access-Control-Allow-Origin', '*'
  res.header 'Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept'
  next()


SpinCycle       = require('spincycle')

AuthenticationManager = require('./AuthenticationManager')
QPAPILogic = require('./server/Logic')

app.use express.static("app")

#app.use('/socket.io', express.static('app2/bower_components/socket.io-client'))
#--------------------------------------------------> Set up Message Router
authMgr         = new AuthenticationManager(app)
messageRouter   = new SpinCycle(authMgr, dbUrl, null, app, 'rethinkdb')
#--------------------------------------------------> Express Routing
new SpinCycle.HttpMethod(messageRouter, app, '/api/')
#<-------------------------------------------------- Express Routing
#--------------------------------------------------> WS Routing
new SpinCycle.WsMethod(messageRouter, server)
#<-------------------------------------------------- WS Routing
#--------------------------------------------------> Set up things
new QPAPILogic(messageRouter)
#<-------------------------------------------------- Set up things






