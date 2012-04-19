module.exports = (app) ->

  app.get "/", require "../app/controllers/home"
