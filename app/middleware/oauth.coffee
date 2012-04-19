module.exports = (app, events, config) ->

  {trace, consumer, provider} = config

  # ----------------------------------------------------------------------------------------------------
  # helpers
  # ----------------------------------------------------------------------------------------------------

  consumerUrl = -> consumer.url.replace "{port}", app.address().port

  store = (req, key, value) ->
    ns = if req.session.oauth then req.session.oauth else req.session.oauth = {}
    if typeof key is "function"
      key.call ns
    else
      if value?
        ns[key] = value
      else if value is null
        delete ns[key]
      ns[key]

  storeAuth = (req, json) ->
    store req, ->
      @[k] = v for own k, v of json
      @authenticated = true
      @expires_time = Date.now() + (parseInt(json.expires_in) * 1000)

  get = (reason, url, done, fail) ->
    parts = url.parse()
    secure = parts.protocol is "https:"
    transport = if secure then require "https" else require "http"
    options =
      host: parts.host
      port: parts.port or (if secure then 443 else 80)
      path: parts.pathname + parts.search
      headers:
        "Accept": "application/json"
        "X-Route": provider.route
    next = (ores) ->
      body = ""
      json = null
      ores.on "data", (chunk) -> body = body + chunk
      ores.on "end", ->
        try
          json = JSON.parse body if body
          if ores.statusCode is 200
            if trace
              console.log "OAuth2:#{reason} -> RESPONSE"
              console.log json
            done json
          else
            fail(if json?.error_description then json.error_description else if body then body else ores.statusCode)
        catch ex
          fail ex
    console.log "OAuth2:#{reason} -> GET #{url.toString()}" if trace
    transport.get(options, next).on("error", fail)
  
  redirect = (reason, res, url) ->
    console.log "OAuth2:#{reason} -> REDIRECT #{url.toString()}" if trace
    res.redirect url.toString(), 303

  class Url
    constructor: (@base, @path, @params) ->
    parse: -> require("url").parse @toString()
    toString: -> "#{@base}#{@path}?#{(k + "=" + encodeURIComponent v for own k, v of @params).join "&"}"

  # ----------------------------------------------------------------------------------------------------
  # routes
  # ----------------------------------------------------------------------------------------------------

  app.get consumer.routes.connect, (req, res) ->
    store req, "host", provider.url
    hash = require("crypto").createHash
    store req, "state", hash("md5").update(Date.now().toString()).digest("hex")
    url = new Url provider.url, provider.authorize,
      response_type: "code"
      client_id: consumer.id
      redirect_uri: "#{consumerUrl()}#{consumer.routes.connected}"
      scope: consumer.scope
      state: store req, "state"
    redirect "CONNECT", res, url

  app.get consumer.routes.connected, (req, res) ->
    code = req.query.code
    if code
      store req, "code", code
      url = new Url provider.url, provider.accessToken,
        grant_type: "authorization_code"
        code: code
        redirect_uri: "#{consumerUrl()}#{consumer.routes.connected}"
        client_id: consumer.id
        client_secret: consumer.secret
      done = (json) ->
        storeAuth req, json
        events.connected req, res
      fail = (err) ->
        console.error err.stack
        events.error "Failed to connect to OAuth provider during connected callback: #{err}", req, res
      get "CONNECT", url, done, fail
    else if req.query.error
      store req, "state", null
      events.denied req.query.error, req, res
    else
      events.error "Invalid connected callback request: OAuth2 code not specified", req, res

  app.get consumer.routes.disconnect, (req, res) ->
    req.session.destroy()
    # @todo get return address from server config
    url = new Url provider.url, provider.logout, redirect_uri: "#{consumerUrl()}#{consumer.routes.disconnected}"
    redirect "DISCONNECT", res, url

  app.get consumer.routes.disconnected, (req, res) ->
    events.disconnected req, res
  
  # ----------------------------------------------------------------------------------------------------
  # middleware
  # ----------------------------------------------------------------------------------------------------
  
  (req, res, next) ->
    
    store req, ->
      if @authenticated and -(Date.now() - @expires_time) < (consumer.threshold * 1000)
        url = new Url provider.url, provider.accessToken,
          grant_type: "refresh_token",
          refresh_token: @refresh_token
          scope: consumer.scope
        done = (json) ->
          storeAuth req, json
          next()
        fail = (err) ->
          events.error "Failed to connect to OAuth provider during refresh: #{err}", req, res
        get "REFRESH", url, done, fail
      else
        next()
