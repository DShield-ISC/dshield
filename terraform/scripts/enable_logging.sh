#!/bin/bash
sudo tee -a /srv/cowrie/cowrie.cfg << EOF 

[output_jsonlog]
enabled = true
logfile = \${honeypot:log_path}/cowrie.json
epoch_timestamp = false
EOF

sudo tee -a /etc/logrotate.d/dshield << EOF

/srv/cowrie/var/log/cowrie/cowrie.json
{
	rotate 4
	daily
	missingok
	notifempty
	compress
	maxsize 100M
}
EOF
