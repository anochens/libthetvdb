#!/usr/bin/ruby

require 'lib/libthetvdb.rb'

Thetvdb.apikey=`cat ./apikey.txt`.chomp
pp it=Thetvdb.search("scrubs")
#pp Thetvdb.getAllEpisodes("75760","two weeks ago")
#pp Thetvdb.getAllSeriesIds()
#pp Thetvdb.infoForSeriesId("75760")
