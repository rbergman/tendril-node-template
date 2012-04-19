http = require "request"
{app, oauth} = require "../../config/env"
encode = encodeURIComponent

module.exports =
  get: (options) -> request "GET", options
  post: (options) -> request "POST", options
  put: (options) -> request "PUT", options
  del: (options) -> request "DELETE", options

request = (method, options) ->
  {path, params, matrix, query, defaults, body, auth, next} = options
  tparams = filter tokens(path), params, defaults
  mparams = filter matrix or [], params, defaults
  qparams = filter query or [], params, defaults
  path = reify path, tparams, defaults
  url = "#{oauth.provider.url}/connect#{path}"
  url += ";#{encode k}=#{encode v}" for own k, v of mparams
  if Object.keys(qparams).length > 0
    url += "?" + ("#{encode k}=#{encode v}" for own k, v of qparams).join "&"
  args =
    method: method
    url: url
    headers:
      "Accept": "application/json"
      "Access_Token": auth.access_token
  if body and method is "POST" or method is "PUT"
    args.body = body
    args.headers["content-type"] = "application/xml"
  start = Date.now() if app.trace
  req = http args, (err, res, data) ->
    code = res.statusCode
    status = require("http").STATUS_CODES[code]
    console.warn "-> #{method} #{url}\n<- #{code} #{status} [#{Date.now() - start}ms]" if app.trace
    if err
      next err, undefined, code
    else
      try
        json = JSON.parse data if res.headers["content-type"] is "application/json"
        err = new Error "Unexpected response code: #{code} #{status}" if code < 200 or code >= 300
        next err, json or data, code
      catch ex
        next ex, undefined, code

tokens = do ->
  cache = {}
  (path) ->
    list = cache[path]
    if not list
      list = cache[path] = []
      replace path, (match, name) -> list.push name
    list

dasherize = (name) ->
  name.replace(/([a-z])([A-Z])/g, (_, prev, c) -> prev + "-" + c.toLowerCase()).toLowerCase()

camelize = (name) ->
  name.replace /\-([a-z])/g, ($0, c) -> c.toUpperCase()

filter = (names, values, defaults={}) ->
  result = {}
  for src in [defaults, values]
    for own k, v of src
      if k in names
        result[k] = v
      else
        dk = dasherize k
        if dk isnt k and dk in names
          result[dk] = v
  result

replace = (path, fn) ->
  path.replace /\{([\w\-]+)\}/g, fn

reify = (path, values, defaults={}) ->
  replace path, (match, name) ->
    alt = camelize name
    if values[name]? then values[name]
    else if values[alt]? then values[alt]
    else if defaults[name]? then defaults[name]
    else if defaults[alt]? then defaults[alt]
    else ""
