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

    #readFile takes a filename, and optionally the maximum num of lines to read
    #returns the lines read as an array.
    def readFile file, max_lines=0
      counter=0
      read_lines=[]
      File.open(file, 'r') {|f|
        while (line= f.gets and counter<=max_lines)
          read_lines << line
          counter+=1 unless max_lines==0
        end
      }
      read_lines
    end

    def agent(timeout=300)
       a = Mechanize.new
       a.read_timeout = timeout if timeout
       a.user_agent_alias= 'Mac Safari'
       a   
    end

    def initMirror
      mirrors_xml = XmlSimple.xml_in agent.get("http://www.thetvdb.com/api/#{@apikey}/mirrors.xml").body
      mirrors_xml['Mirror'][0]['mirrorpath'][0]
    end
  
    def mirror
      @mirror
    end

    def start
      if @apikey.nil?
         begin
           @apikey= File.exist?(File.dirname(__FILE__)+'/apikey.txt') ? readFile(File.dirname(__FILE__) +'/apikey.txt', 1).first.strip : 
             readFile(File.dirname(__FILE__)+'/../apikey.txt').first.strip
         rescue Errno::ENOENT => e
           if e.to_s[/No such file.+apikey\.txt/]
             puts "Get an apikey please"
             raise e
           end
         end
      end   
      @mirror=initMirror
    end
    attr_accessor :apikey
    attr_reader :mirror

		#Format results from TVDB
		#return a hash with the parts we store in the database.
		def formatTvdbResults( tvdbResults )
			raise "formatTvdbResults() is not supposed to deal with nil results, sort that out first." if tvdbResults.nil?
			results=[]
			tvdbResults['Series'].each_index {|i| tvdbResults['Series'][i].each_key {|item|
			  results[i]||={}
				results[i]['tvdbSeriesID'] = \
					tvdbResults['Series'][i][item] if item=='id'
				results[i]['imdbID'] = \
					tvdbResults['Series'][i][item] if item=='IMDB_ID'
				results[i]['Title'] = \
					tvdbResults['Series'][i][item] if item=='SeriesName'
			}}
			results.each_index {|i|
				results[i]['EpisodeList']= getAllEpisodes(results[i]['tvdbSeriesID'])
			}

			results
		end

		def getAllEpisodes( seriesID, since = nil )
			raise "getAllEpisodes() only takes seriesID" if seriesID.class==Fixnum
         start if mirror.nil?

			episodeList=[]

			#TheTVDB runs slowly sometimes, dont want to crash fail, retry instead
			body = XmlSimple.xml_in( agent.get("http://thetvdb.com/api/#{@apikey}/series/#{seriesID}/all/en.xml").body )

			unless body.has_key?('Episode')
				puts "#{seriesID} has no episodes?"
				return []
			end

			body['Episode'].each {|episode|
				episode['EpisodeName'][0]='' if episode['EpisodeName'][0] == {}

            #skip episodes without names
            next if episode['EpisodeName'][0] == ''

            sincedate = Chronic.parse(since)
            airdate   = Chronic.parse(episode['FirstAired'][0])    
            next if airdate.nil?

            # sincedate.nil?  means no date was passed, so show all
            # airdate.nil? means a really new episode with no air adte
            # since < air means it is in the target range 
            if sincedate.nil? ||  sincedate <= airdate 

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
            end
			}

			episodeList 
		end

    #Search Thetvdb.com for str
    def search str, retries=2
      start if mirror.nil?
      begin
        url="#{@mirror}/api/GetSeries.php?seriesname=#{ERB::Util.url_encode str}"
        XmlSimple.xml_in( agent.get("#{@mirror}/api/GetSeries.php?seriesname=#{ERB::Util.url_encode str}").body )
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

    def getAllSeriesIds
		start if mirror.nil?

      #read from the local file to save server loads
		ids = IO.readlines( File.dirname(__FILE__) + "/updates_all.txt" ).map{|l| l.gsub("\n","") }

		return ids
    end

	 def infoForSeriesId(seriesID)
	   start if mirror.nil?

		begin 
			body = XmlSimple.xml_in( agent.get("http://thetvdb.com/api/#{@apikey}/series/#{seriesID}/en.xml").body )

			body = body["Series"][0]
			body.each{|k,v| body[k] = v[0]}

		rescue Mechanize::ResponseCodeError
         body = nil
		end
		body
	 end
  end
end

