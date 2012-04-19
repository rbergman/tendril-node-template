{GreenButton} = require "../lib/sdk"

module.exports = (req, res) ->
  
  doRender = (err, data) ->
    req.flash "error", err if err
    res.render "home", {data: data}
  
  if req.session.user
    GreenButton(req).load doRender
  else
    doRender()
