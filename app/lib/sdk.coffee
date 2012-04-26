{get, post, put, del} = require "./http"
moment = require "moment"

module.exports =

  User: (req) ->
  
    load: (options={}) -> get
      path: "/user/{user-id}"
      defaults:
        userId: "current-user"
      params: options.params
      auth: req.session.oauth
      next: getNext options

  UserAccount: (req) ->

    load: (options={}) -> get
      path: "/user/{user-id}/account/{account-id}"
      defaults:
        userId: "current-user"
        accountId: "default-account"
      params: options.params
      auth: req.session.oauth
      next: getNext options

  UserLocation: (req) ->

    load: (options={}) -> get
      path: "/user/{user-id}/account/{account-id}/location/{location-id}"
      defaults:
        userId: "current-user"
        accountId: "default-account"
        locationId: "default-location"
      params: options.params
      auth: req.session.oauth
      next: getNext options

  UserLocationProfile: (req) ->

    load: (options={}) -> get
      path: "/user/{user-id}/account/{account-id}/location/{location-id}/profile"
      defaults:
        userId: "current-user"
        accountId: "default-account"
        locationId: "default-location"
      params: options.params
      auth: req.session.oauth
      next: getNext options

  GreenButton: (req) ->
  
    load: (options={}) -> get
      path: "/greenbutton"
      query: ["resolution", "from", "to", "max-results"]
      defaults:
        resolution: "HOURLY"
        from: moment().subtract("weeks", 4).format("MM/DD/YYYY")
        to: moment().format("MM/DD/YYYY")
      params: options.params
      auth: req.session.oauth
      next: getNext options

getNext = (options) -> if typeof options is "function" then options else options.next
