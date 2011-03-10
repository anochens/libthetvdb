=begin
		Copyright 2009 Jeff Welling (jeff.welling (a) gmail.com)
		This file is part of libthetvdb.

    libthetvdb is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    libthetvdb is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with libthetvdb.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'rubygems'
require 'mechanize'
require 'xmlsimple'
require 'erb'

module Thetvdb

	class << self

		attr_accessor :apikey

		def agent(timeout=300)
			a = Mechanize.new
			a.read_timeout = timeout if timeout
			a.user_agent_alias= 'Mac Safari'
			a   
		end

      #get rid of some wierd stuff
		def formatInside( inside )
			inside = inside[0] if inside.is_a?(Array) && inside.length==1
			inside.each{|k,v|
				# get rid of the common ["something here"], where array unneeded
				v = v[0] if v.is_a?(Array) && v.length==1

				#turn lists with seperators into arrays
    			v = v.split("|") if v.is_a?(String) && v.count("|") > 1

				#get rid of empty elements from the array
				v.delete("") if v.is_a?(Array)

				#replace {}s with nils; it's more intuitive to test for nil
				v = nil if v == {}

				#set the inside to the changed version
         	inside[k] = v
			}
			inside
		end

		def getAllEpisodes( seriesID, since = nil )
			raise "getAllEpisodes() only takes seriesID" if seriesID.class==Fixnum

			episodeList=[]

			#if since is specified, we should use the updates url instead,
			#but more later on that

			url = "http://thetvdb.com/api/#{@apikey}/series/#{seriesID}/all/en.xml"
			body = xml_get(url)

			unless body.has_key?('Episode')
				puts "#{seriesID} has no episodes?"
				return []
			end

			body['Episode'] ||= []
			body['Episode'].map! {|episode| formatInside(episode) }
			body['Episode'] 
		end

    #Search Thetvdb.com for str
    def search(str)
		str = ERB::Util.url_encode str 
		url="http://thetvdb.com/api/GetSeries.php?seriesname=#{str}"
		xml_get(url)
    end

	 #this is pretty hacky for now, will fix eventually
    def getAllSeriesIds
      #read from the local file to save server loads
		ids = IO.readlines( File.dirname(__FILE__) + "/updates_all.txt" ).map{|l| l.chomp }

		return ids
    end

	 def getFullSeriesRecord(seriesID)
		url = "http://thetvdb.com/api/#{@apikey}/series/#{seriesID}/all/en.xml"
		full_record = xml_get(url)
		
      full_record["Series"] = formatInside(full_record["Series"]) 

		fill_record["Episode"] ||= [] #deal with having no episodes
      full_record["Episode"].map!{|episode| formatInside(episode) }
			
		full_record
	 end        

	 def infoForSeriesId(seriesID)
		url = "http://thetvdb.com/api/#{@apikey}/series/#{seriesID}/en.xml"
		series = xml_get(url)
		series = formatInside(series["Series"])
		
		series
	 end

	 def xml_get(url, retries = 3)
		begin
			body = XmlSimple.xml_in( agent.get(url).body )
		rescue Mechanize::ResponseCodeError
         body = nil
			raise
		rescue Errno::ETIMEDOUT => e
			(retries-=1 and retry) if retries > 0
			raise e
		rescue Timeout::Error => e
			(retries-=1 and retry) if retries > 0
			raise e
		rescue REXML::ParseException => e
			#return empty and continue normally, response from Thetvdb is malformed.
			return []
		end    
      body
	 end
  end
end

