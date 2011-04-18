=begin
	Copyright 2009 Jeff Welling (jeff.welling (a) gmail.com)
	This file is part of libthetvdb.

	libthetvdb is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	libthetvdb is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with libthetvdb.	If not, see <http://www.gnu.org/licenses/>.
=end

require 'rubygems'
require 'mechanize'
require 'xmlsimple'
require 'erb'

module Thetvdb

	class << self

		attr_accessor :apikey
		attr_accessor :pretty_format

		def agent(timeout=300)
			pretty_format ||= false
			a = Mechanize.new
			a.read_timeout = timeout if timeout
			a.user_agent_alias= 'Mac Safari'
			a
		end

		# break arrays in "|elem1|elem2|" format into a real array
		def break_array(arr)
			#turn lists with seperators into arrays
			arr = arr.split("|") if arr.is_a?(String) && arr.count("|") > 1

			#get rid of empty elements from the array
			arr.delete("") if arr.is_a?(Array)

			#return [] instead of a nil
			arr ||= []
			arr = [arr] unless arr.is_a?(Array)

			arr
		end	

		#extracts the element from an array of length 1
		def extractElemFromArray(arr)
			return arr[0] if arr.is_a?(Array) && arr.length == 1
			arr
		end	

		#get rid of some wierd stuff
		def formatInside( inside )
			inside = Thetvdb.extractElemFromArray(inside)
			inside.each{|k,v|
				v = Thetvdb.extractElemFromArray(v)
				v = Thetvdb.break_array(v)

				#replace {}s with nils; it's more intuitive to test for nil
				v = nil if v == {}

				#set the inside to the changed version
				inside[k] = v
			}
			inside
		end

		def getAllEpisodes( seriesID )
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
			body['Episode'].map! {|episode| formatInside(episode) } if pretty_format
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
			
			full_record["Series"] = formatInside(full_record["Series"]) if pretty_format

			full_record["Episode"] ||= [] #deal with having no episodes
			full_record["Episode"].map!{|episode| formatInside(episode) } if pretty_format
				
			full_record
		 end	

		 def infoForSeriesId(seriesID)
			url = "http://thetvdb.com/api/#{@apikey}/series/#{seriesID}/en.xml"
			series = xml_get(url)
			series = series["Series"]
			series = formatInside(series) if pretty_format
			
			series
		 end

		 # from here on, things are private

		 private 

		 def xml_get(url, retries = 300)
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
				#return empty and continue normally, 
				#response from Thetvdb is malformed.

				return []
			end	
			body
		 end
	end
end
