require 'nokogiri'
require 'open-uri'
require 'optparse'

#Option parser
@options = Hash.new
OptionParser.new do |o|
	o.on("-t", "--title", "Provide title"){ |t| @options["title"] = t }
	o.on("-l", "--link" , "Provide 1st chapter link"){ |l| @options["start"] = l }
end.parse!

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

def classFinder(url) #if you add custom classes, add the pattern to search for to verify them here
	patterns = {
		"royalroad" => RRChapter
	}
	@chapclass = ""
	patterns.keys.each do |k|
		@chapclass = if url.include? k
			patterns[k]
		end
	end
	if @chapclass == ""
		@chapclass = Chapter
	end
	return @chapclass
end

url = "https://www.royalroad.com/fiction/25225/delve/chapter/368012/1-woodland"

ch1 = classFinder(url).new url
delve = Book.new ch1, "Delve"
delve = delve.shelve "delve.html"