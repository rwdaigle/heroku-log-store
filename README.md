# heroku-log-drain

heroku-log-drain is an evented Ruby service for receiving and storing syslog messages over HTTP. Its purpose is
to function as a Heroku [https log drain](https://devcenter.heroku.com/articles/labs-https-drains) which stores log data
in a Postgres database for *simple* querying and inspection.

heroku-log-drain makes no assumptions about the format of your data, merely dumping payload data into a Postgres table
which you can then query yourself. Think of heroku-log-drain as a *long-term but queryable* place to store your log data.
Future versions may built simple introspection functionality on top of this data, but I reserve the right to keep it nice
and dumb.

Currently, heroku-log-drain is seeing light action in production. Please report any issues in the project's
Github issue tracker.

## Deploy

To have heroku-log-drain store your logs, deploy an instance of heroku-log-drain to Heroku. Yes, a log-drain app on Heroku, draining logs from another app on Heroku. Just don't create a circular reference or else the universe might rip.

*Note:* This assumes you have the [Heroku Toolbelt](https://toolbelt.heroku.com/) installed locally.
Also, these steps install the `dev` [heroku-postgresql](https://addons.heroku.com/heroku-postgresql) add-on which
is limited to 10K rows. This is not a lot of capacity as logs can be quite chatty. It is recommended that you use at least
the `basic` postgres database. If you want to do this just specify `heroku-postgresql:basic` below instead.

```term
$ git clone git://github.com/rwdaigle/heroku-log-drain.git
$ cd heroku-log-drain
$ heroku create log-drain
$ heroku config:set RACK_ENV=production
$ heroku addons:add heroku-postgresql:dev
$ git push heroku master
```
Your drain should now be deployed and running on Heroku, although it will need to be configured before use.

## Configure

To configure your heroku-log-drain instance you need to create the basic table structure in the database.
There is a process type called `migrate` you can invoke with `heroku run` that will do this for you.

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

![](http://f.cl.ly/items/3Q3V2m0Z1S1R032d2F1N/Image%202012-12-14%20at%208.17.24%20PM.png)

Follow the instructions in the app to properly setup security and to set the app as a log drain
for another app. If you weren't able to reach this point, please submit an issue to the project's
Github issue tracker.

## Querying

heroku-log-drain is not a replacement for [Papertrail](https://addons.heroku.com/papertrail) or
any other true log-aggregation and eventing service. As such, its interface is limited to SQL.

Once your heroku-log-drain is receiving log data you can query/filter it by opening a Postgres shell from
the log-drain app.

```term
$ heroku pg:psql
u7ejsaid=#
```

The `events` table is where the goods are. Here is its schema:

```sql
=# \d events
                                      Table "public.events"
     Column      |           Type           |                      Modifiers                      
-----------------+--------------------------+-----------------------------------------------------
 id              | bigint                   | not null default nextval('events_id_seq'::regclass)
 emitted_at      | timestamp with time zone | 
 received_at     | timestamp with time zone | default now()
 priority        | integer                  | 
 syslog_version  | integer                  | 
 hostname        | character(255)           | 
 appname         | character(255)           | 
 proc_id         | character(255)           | 
 msg_id          | character(255)           | 
 structured_data | text                     | 
 message         | text                     | 
Indexes:
    "events_pkey" PRIMARY KEY, btree (id)
    "events_emitted_at" btree (emitted_at)
```

The rest is up to you.

Let [@rwdaigle](https://twitter.com/rwdaigle) know if you have any special requests.