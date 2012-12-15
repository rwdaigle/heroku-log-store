clorox
======

Clear your (log) drains.

Clorox is an evented Ruby service for receiving and storing syslog messages over HTTP. It's original purpose is
to function as a Heroku [https log drain](https://devcenter.heroku.com/articles/labs-https-drains).

Clorox makes no assumptions about the format of your data, merely dumping payload data into a Postgres table
which you can then query yourself. Think of clorox as a place to dump your log data until you know what
you want to do with it. Future versions may built simple introspection functionality on top of this data, but I 
reserve the right to keep it real dumb.

Currently, clorox is seeing light action in production. Please report any issues in the project's
Github issue tracker.

## Deploy

To have clorox store your logs, deploy an instance of Clorox to Heroku. Yes, a log-drain app on Heroku, draining logs from another app
on Heroku. Just don't create a circular reference or else the universe might rip.

*Note:* This assumes you have the [Heroku Toolbelt](https://toolbelt.heroku.com/) installed locally.
Also, these steps install the `dev` [heroku-postgresql](https://addons.heroku.com/heroku-postgresql) add-on which
is limited to 10K rows. This is not a lot of capacity as logs can be quite chatty. It is recommended that you use at least
the `basic` postgres database. If you want to do this just specify `heroku-postgresql:basic` below.
instead.

```term
$ git clone git://github.com/rwdaigle/clorox.git
$ cd clorox
$ heroku create log-drain
$ heroku config:set RACK_ENV=production
$ heroku addons:add heroku-postgresql:dev
$ git push heroku master
```

Your app should now be deployed and running on Heroku, although it will need to be configured before opening it.

## Configure

To configure your Clorox instance you need to migrate the database. There is a process type called `migrate`
you can invoke with `heroku run` that will do this for you.

```term
$ heroku run migrate
Running `migrate` attached to terminal... up, run.4179
WARNING:  => is deprecated as an operator name
DETAIL:  This name may be disallowed altogether in future versions of PostgreSQL.
```

Now open the app to see instance-specific instructions such as setting up http basic authentication and
setting the instance to be a log drain for a source app.

```term
$ heroku open
Opening log-drain... done
```

You will be prompted for a username/password. Until the credentials are explicitly set, you can login
with anything.

![](http://f.cl.ly/items/2I3T1V271C3m2H39171F/Image%202012-12-14%20at%207.28.36%20PM.png)

Leave both fields blank and click "Log in". You should now see instructions similar to:

![](http://f.cl.ly/items/0Q2V08192a0L3v1l1F1D/Image%202012-12-14%20at%207.30.34%20PM.png)

Follow the instructions in the app to properly setup security and to set the app as a log drain
for another app. If you weren't able to reach this point, please submit an issue to the project's
Github issue tracker.