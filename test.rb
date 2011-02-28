#!/usr/bin/ruby

require 'lib/libthetvdb.rb'

#pp it=Thetvdb.search("show here")
pp Thetvdb.getAllEpisodes("75760")
