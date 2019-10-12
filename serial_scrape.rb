require 'nokogiri'
require 'open-uri'
require 'optparse'

#Option parser
title = ""
start = ""
OptionParser.new do |o|
	o.banner = "testing"
	o.on("-t", "--title of SERIAL", "Provide title") do |serial|
		title << serial
	end
	o.on("-s", "--start LINK" , "Provide 1st chapter link") do |link|
		start << link
	end
end.parse!
puts @opts

#Generic chapter reading class
class Chapter
	def initialize(url)
		@doc = 		Nokogiri::HTML open url
		@url = 		url
	end

	def title ;		@doc.css("h1").first.content ; end
	def text ; 		@doc.css("p").to_s; end
	def url ;		@url; end

	def linksearch(pattern)
		find = false
		links = @doc.css "a"
		links.each do |l|
			if l.content.upcase.include?(pattern)
				find = l["href"]
			end
		end
		if find
			unless find[0..3] == "http"
				domain_index = @url.index("/",8)
				find = @url[0..domain_index-1] + find
			end
		end
		return find
	end

	def nextch;		self.linksearch "NEXT"
	end
	def prevch;		self.linksearch "PREV" 
	end
end 

class RRChapter < Chapter
	def text
		foreword = @doc.css("div.author-note")
		doc = @doc.css("div.chapter-inner.chapter-content").first
		doc = doc.css "p"
		return "<div align=\"right\"><i>#{foreword.to_s}</i></div>\n#{doc.to_s}\n"
	end #Chapter class customized for royalroad
end

class WPChapter < Chapter
	def text
		return @doc.css("div.entry-content").first.to_s
	end
end

class WardChapter < Chapter
	def text
		t = @doc.css("div.entry-content").first.css("p")
		return t[1..t.length-2].to_s
	end
end

class PGTEChapter
	def title
		return @doc.css("h1.entry-title").first
	end
	def text
		return @doc.css("div.entry-content p").to_s
	end
end

class Book
	def initialize(chap, title="Beginning")
		@next_url = chap.nextch
		@title = title
		@chap = chap
		@body = ""
		@toc = "<h1>Table of Contents</h1>"
		@ind = 1
		until @next_url == false
			@next_url = @chap.nextch
			@body << "<h1 id=\"chapter#{@ind.to_s}\">#{@chap.title}</h1>\n"
			@body << @chap.text + "\n"
			@toc  << "<a href=\"#chapter#{@ind}\">#{@chap.title}</a><br>\n"
			@ind  += 1
			if @next_url
				@chap = @chap.class.new @next_url
			end
		end
	end
	def full_text
		title = "<h1>#{@title}</h1>\n"
		return title + @toc + @body
	end
	def shelve(fname);
		File.open fname, 'w' do |f| ; f.puts self.full_text;
		end
	end 
end

def classFinder(url) #if you add custom classes, add the pattern to search for to verify them here.
	patterns = {
		"royalroad" => RRChapter,
		"wordpress" => WPChapter,
		"parahumans" => WardChapter,
		"practical" => PGTEChapter
	}
	@chapclass = ""
	patterns.keys.each do |k|
		@chapclass = if url.include? k
			patterns[k]
		else
			@chapclass
		end
	end
	puts @chapclass
	if @chapclass == ""
		@chapclass = Chapter
	end
	return @chapclass
end

url = start

ch1 = classFinder(url)
puts ch1.class 
ch1 = ch1.new url
book = Book.new ch1, title
book = book.shelve "#{title}.html"