{User} = require "../lib/sdk"

exports.events =
  
  connected: (req, res) ->
    User(req).load (err, user) ->
      if err
        req.flash "error", "Unable to fetch user information after OAuth log in"
      else
        req.session.user = user
      res.redirect "/", 303

  disconnected: (req, res) ->
    res.redirect "/", 303

  denied: (err, req, res) ->
    req.flash "error", err
    res.redirect "/", 303
  
  error: (err, req, res) ->
    req.flash "error", err
    res.redirect "/", 303
