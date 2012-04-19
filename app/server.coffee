express = require "express"
env = require "../config/env"
oauth =
  config: env.oauth
  middleware: require "./middleware/oauth"
  events: require("./controllers/oauth").events

app = module.exports = express.createServer()

app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session secret: env.app.secret
  app.use oauth.middleware app, oauth.events, oauth.config
  app.use app.router
  app.use express.static __dirname + "/../public"

app.configure "development", ->
  app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure "production", ->
  app.use express.errorHandler()

app.dynamicHelpers
  request: (req, res) -> req
  session: (req, res) -> req.session
  user: (req, res) -> req.session.user
  messages: require "express-messages-bootstrap"

require("../config/routes")(app)

app.listen (process.argv?.length and parseInt process.argv[2]) or 3001
console.log "Listening on port #{app.address().port} in #{app.settings.env} mode"
