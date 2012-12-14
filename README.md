clorox
======

Clear your (log) drains.

**Clorox** is an evented Ruby service for receiving and storing syslog messages over HTTP. It's original purpose is
to function as a Heroku [https log drain](https://devcenter.heroku.com/articles/labs-https-drains).

Clorox makes no assumptions about the format of your data, merely dumping payload data into a Postgres hstore
column which you can then query yourself. Think of clorox as a place to dump your log data until you know what
you want to do with it. Future versions may built simple introspection functionality on top of this data, but I 
reserve the right to say "no".

Currently, clorox is not a functioning service. Hopefully that will be remedied in the coming days/weeks?