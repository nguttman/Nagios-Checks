## This directory contains 5 Nagios check scripts, one support script and and a short (10sec) audio file:

#### check_media_relay
A Generic script tat can be used to simulate both sides of media traffic for any media relay and return statistics. It is used by check_media_relay, but can (and is) used by other scripts as well. It (by default) uses the .wac file here but can use any .wav file.

#### check_rtpproxy_calls
A simple little hack that is run locally on a media relay box and tires to estimate how many calls are active though any/all RTPProxy processes running.

#### check_rtpproxy.pl
The first generation of real checks meant to be run from a nagios server/slave. It queries an Opensips' nh_sockets table and then check to see if tho listed RTP Proxies are responsive. This check was designed for a very specific setup and will likely have to be modifed to be of any use.

#### check_rtpproxy
This no longer used a DB and now also gets some useful data from the RTPProxy like the number of active sessions.

#### check_rtpproxy2
This is the current version and all further development is being based off of this. It adds a lot of extra reporting from previous versions.

#### check_rtpproxy_media
This script has all of the features of check_rtpproxy2, but it also calls check_media_relay and evaluates for packet loss on the media relay.

Note that there is an event handler script under development which can also be found in this repository.

Enjoy

Noah Guttman
