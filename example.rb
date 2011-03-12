#!/usr/bin/ruby

require 'lib/libthetvdb.rb'

#To set the apikey use:
#Thetvdb.apikey="MY_API_KEY_HERE"
Thetvdb.apikey=`cat ./apikey.txt`.chomp

#Turns on pretty format (will make much slower, but better formatted)
# makes ["EpisodeName"] just "EpisodeName"
# makes ["|actor1|actor2|" into ["actor1","actor2"]
#Thetvdb.pretty_format = true

#get series info and all episode info
#same result as infoForSeriesId() followed by getAllEpisodes()
#use this instead, because it is more efficient
pp Thetvdb.getFullSeriesRecord("75760")

#get all episodes for a given series, by id
#pp Thetvdb.getAllEpisodes("75760")

#get all of the series id's as an array
#pp Thetvdb.getAllSeriesIds()

#search the db for shows by name, multiple things returned
#pp Thetvdb.search("scrubs")

#gets just series information for a given show
#pp Thetvdb.infoForSeriesId("75760")
