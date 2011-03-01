#!/usr/bin/ruby

require 'lib/libthetvdb.rb'

#pp it=Thetvdb.search("ow here")
pp Thetvdb.getAllEpisodes("75760","two weeks ago")
