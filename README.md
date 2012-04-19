# About

This sample application is provided to kickstart app development with the [Tendril Connect HTTP APIs](https://dev.tendrilinc.com/docs).  It provides a barebones [Node.js](http://nodejs.org)/[Express](http://expressjs.com) application with working OAuth2 client support baked-in to make you productive writing apps with our APIs as quickly as possible.  It also provides optional support for easy deployment to [Heroku](http://www.heroku.com).

This app is developed using [Coffee Script](http://coffeescript.org) but as a Node app you can use JavaScript as the language for your controllers (or other code) as well, at your discretion, with no additional configuration.  The simple example client SDK can be used from JavaScript seamlessly, despite being developed in Coffee Script, so use the language that most appeals to you.  Jade was also chosen for view templating as the default option in Express, but reconfiguring the app to use another templating language is a simple exercise.  See the [Express Guide](http://expressjs.com/guide.html) for more information.

# Installation

First clone the repo:

	git clone git@github.com:rbergman/tendril-node-template.git <your project name>

Then, with [Node.js](http://nodejs.org) v0.6.x:

	cd <your project name>
	npm install -g coffee # if not already installed
	npm install

Next:

	cp config/env.coffee.sample config/env.coffee

Edit env.coffee to configure a custom session secret for your app.  This can be any secret pass phrase you deem appropriate.

Then at [Tendril's developer site](https://dev.tendrilinc.com), create an app to acquire an OAuth2 app id and key.  Further edit env.coffee to set these values.  At this point you should be ready to start the server like so:

	./server [server port]

Or:

	coffee ./app/server.coffee [server port]

The server will start on port 3001, unless you optionally specify your own port in the commands above.
