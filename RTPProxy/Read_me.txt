This directory contains 4 Nagios check scripts:
	check_rtpproxy_calls - a simple little hack that is run locally on a media relay box and tires to estimate how many calls are active though any/all RTPPoxy processes running.
	check_rtpproxy.pl - the first generation of real checks meant to be run from a nagious server/slave. It queries an Opensips' nh_sockets table and then check to see if tho listed RTP Proxies are responsive.
		This check was designed for a very specific setup and will likely have to be modifed to be of any use.
	check_rtpproxy - This no longer used a DB and now also gets some usefull data from the RTPPorxy like the number of active sessions.
	check_rtpproxy2 - this is the current version and all further development is being based off of this. It adds a lot of extra reporting from previous versions.

Note that there is an event handler script under develpment which can also be found in this repository.

Enjoy

Noah Guttman