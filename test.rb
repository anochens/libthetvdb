#!/usr/bin/ruby

require 'lib/libthetvdb.rb'
pp it=Thetvdb.search('how i met your mother')
pp Thetvdb.getAllEpisodes("75760")
