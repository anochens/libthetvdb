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
				v = v[0] if v.is_a?(Array) && v.length==1
    			v = v.split("|") if v.is_a?(String) && v.count("|") > 1
				v.delete("") if v.is_a?(Array)
				v = nil if v == {}
         	inside[k] = v
			}
			inside
		end

		def getAllEpisodes( seriesID, since = nil )
			raise "getAllEpisodes() only takes seriesID" if seriesID.class==Fixnum

			episodeList=[]

			#if since is specified, we should use the updates url instead, but more later on that

			#TheTVDB runs slowly sometimes, dont want to crash fail, retry instead
			url = "http://thetvdb.com/api/#{@apikey}/series/#{seriesID}/all/en.xml"
			body = xml_get(url)

			unless body.has_key?('Episode')
				puts "#{seriesID} has no episodes?"
				return []
			end

			body['Episode'].each {|episode|
				episode['EpisodeName'][0]='' if episode['EpisodeName'][0] == {}

            #skip episodes without names
            next if episode['EpisodeName'][0] == ''

				#episode has more info if we want it, but this seems good
				episodeList << {
						  "SeasonNumber" => episode['SeasonNumber'][0],
						  "SeasonID" => episode['seasonid'][0],

						  "episode_number" => episode['EpisodeNumber'][0],
						  "name" => episode['EpisodeName'][0],

						  "air_date" => episode['FirstAired'][0],
						  "description" => episode['Overview'][0],

						  "image_location" => episode['filename'][0],
						  "imdb_id" => episode['IMDB_ID'][0],
				}
			}

			episodeList 
		end

    #Search Thetvdb.com for str
    def search str, retries=2
		begin
			str = ERB::Util.url_encode str 
			url="http://thetvdb.com/api/GetSeries.php?seriesname=#{str}"
			xml_get(url)
		rescue Errno::ETIMEDOUT => e
			(retries-=1 and retry) unless retries<=0
			raise e
		rescue Timeout::Error => e
			(retries-=1 and retry) unless retries<=0
			raise e
		rescue REXML::ParseException => e
			#return empty and continue normally, response from Thetvdb is malformed.
			return []
		end
    end

	 #this is pretty hacky for now, will fix eventually
    def getAllSeriesIds
      #read from the local file to save server loads
		ids = IO.readlines( File.dirname(__FILE__) + "/updates_all.txt" ).map{|l| l.gsub("\n","") }

		return ids
    end

	 def getFullSeriesRecord(seriesID)
		url = "http://thetvdb.com/api/#{@apikey}/series/#{seriesID}/all/en.xml"
		full_record = xml_get(url)
		
      full_record["Series"] = formatInside(full_record["Series"]) 

      full_record["Episode"].each{|episode|
			episode = formatInside(episode)
		}

		full_record
	 end        

	 def infoForSeriesId(seriesID)
		url = "http://thetvdb.com/api/#{@apikey}/series/#{seriesID}/en.xml"
		body = xml_get(url)
		body = body["Series"][0]
		body.each{|k,v| body[k] = v[0]}

		body
	 end

	 def xml_get(url)
		begin
			body = XmlSimple.xml_in( agent.get(url).body )
		rescue Mechanize::ResponseCodeError
         body = nil
			raise
      end
      body
	 end
  end
end

