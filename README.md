# About

This sample application is provided to kickstart app development with the [Tendril Connect HTTP APIs](https://dev.tendrilinc.com/docs).  It provides a barebones [Node.js](http://nodejs.org)/[Express](http://expressjs.com) application with working OAuth2 client support baked-in to make you productive writing apps with our APIs as quickly as possible.  It also provides optional support for easy deployment to [Heroku](http://www.heroku.com/).

# Installation

First clone the repo:

	git clone git@github.com:rbergman/tendril-heroku-node.git

Then, with [Node.js](http://nodejs.org) v0.6.x:

	cd tendril-connect-demos
	npm install -g coffee # if not already installed
	npm install

Next:

	cp config/env.coffee.sample config/env.coffee

Edit env.coffee to configure a custom session secret for your app.  This can be any secret pass phrase you deem appropriate.

Then at [Tendril's developer site](https://dev.tendrilinc.com), create an app to acquire an OAuth2 app id and key.  Further edit oauth.coffee to add your app id and secret.  At this point you should be ready to start the server like so:

	./server [server port]

Or:

	coffee ./app/server.coffee [server port]

The server will start on port 3001, unless you optionally specify your own port in the commands above.
