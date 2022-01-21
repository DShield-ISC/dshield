# Logging

By default, the honeypot does minimal logging on the honeypot itself in order to reduce the wear and tear on the SD Cards. Raspberry Pis often fail due to corrupted SD Cards.

You may however want to enable additional logging for debugging or just to see in more detail what events the honeypot is processing

## cowrie

Cowrie offers a number of log formats. One useful log is the JSON log which can be enabled by adding the following lines to /srv/cowrie/cowrie.cfg

```
[output_jsonlog]
enabled = true
logfile = ${honeypot:log_path}/cowrie.json
epoch_timestamp = false
```

This will create a log in 
```
/srv/cowrie/var/log/cowrie.json
```

This log may grow quickly. Watch it, and maybe setup automatic log rotation for it.

## web.py

web.py collects HTTP requests. They are logged in a sqlite database in /srv/www/DB/webserver.sqlite . You may connect to it using:
```
sqlite3 /srv/www/DB/webserver.sqlite
```
The requests are logged to the "requests" table. For example:

Get all user agents: 
```
select useragents from requests
```
Or to get a summary:
```
select count(*) c, useragent from requests group by useragent order by c desc;
```
The date column uses unix timestamps. To get all requests for the last hour:
```
select * from requests where date>strftime('%s','now')-3600;
```



