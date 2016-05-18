# CONFIGURATION DATABASE

The configuration database contains the following tables

requestmatch: this table will match incoming requests to outbound responses

  - url regex
  - header regex (optional. can be a list)
  - serverid
  - pageid

servers: headders and other characteristics identifying a server

pages: the boxy of the page

lookup cache: cache recent lookups to return consistent results

source ip
request
serverid
pageid


  