require 'nokogiri'
require 'open-uri'
require 'optparse'
require 'mail'

#Option parser
@book_title = ""
start = ""
author = ""
kindle = ""
email = ""
password = ""
path = ""
OptionParser.new do |o|
	o.banner = ""
	o.on("-n", "--name NAME", "Provide book name") do |serial|
		@book_title << serial
	end
	o.on("-s", "--start LINK" , "Provide 1st chapter link") do |link|
		start << link
	end
	o.on("-a", "--author NAME", "Provide name of author") do |a|
		author << a
	end
	o.on("-t", "--to EMAIL", "email address to send to") do |k|
		kindle << k
	end
	o.on("-f", "--from EMAIL", "email address to send from") do |f|
		email << f
	end
	o.on("-p", "--password PASSWORD", "Password for the email address to send from") do |p|
		password << p
	end
	o.on("-d","--directory PATH", "Directory to write files to") do |d|
		path << d
		path = path + '/' unless path[-1] == '/' || path.empty?
	end
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

#Custom chapter reading classes
###############
class RRChapter < Chapter #Royalroad
	def text
		foreword = @doc.css "div.author-note"
		doc = @doc.css("div.chapter-inner.chapter-content").first
		doc = doc.css "p"
		return "<div align=\"right\"><i>#{foreword.to_s}</i></div>\n#{doc.to_s}\n"
	end 
end

class WPChapter < Chapter #Wordpress
	def text
		text = @doc.css("div.entry-content").first
		links = text.css("a")
		divs = text.css("div")

		to_remove = []
		links.each do |l|
			to_remove << l.to_s if l.content.upcase.include? "NEXT" or l.content.upcase.include? "PREV"
		end
		divs.each do |d|
			to_remove << d.to_s if d["class"].include? "shar" or d["class"].include? "wpa" if d.keys.join(" ").include? "class"
		end
		stext = text.to_s
		to_remove.each do |r|
			stext = stext.gsub r, ""
		end
		return stext
	end
	def title
		@doc.css("h1.entry-title").first.content
	end
end

class WardChapter < Chapter #Ward/other wildbow works
	def text
		t = @doc.css("div.entry-content").first.css("p")
		return t[1..t.length-2].to_s
	end
end

class PGTEChapter < Chapter #Practical Guide to Evil
	def title
		return @doc.css("h1.entry-title").first.content
	end
	def text
		return @doc.css("div.entry-content p").to_s
	end
end

class WanderingInn < WPChapter #The Wandering Inn
	def initialize(url)
		url = url.gsub ".wordpress", ""
		@doc = 		Nokogiri::HTML open url
		@url = 		url
	end
	def nextch
		nc = self.linksearch "NEXT"
		nc.gsub ".wordpress", "" if nc
		nc
	end
end

#if you add custom classes, add the pattern to search for to verify them here. The last class in the list that matches a given url is the one that's used, so make sure to add custom classes for a given serial at the end.
def classFinder(url)
	patterns = {
		"royalroad" => 				RRChapter,
		"wordpress" => 				WPChapter,
		"parahumans" => 			WardChapter,
		"practicalguidetoevil" => 	PGTEChapter,
		"wanderinginn" =>			WanderingInn
	}
	@chapclass = ""
	patterns.keys.each do |k|
		@chapclass = if url.include? k
			patterns[k]
		else
			@chapclass
		end
	end
	if @chapclass == ""
		@chapclass = Chapter
	end
	return @chapclass
end

class Book
	def initialize(chap, title="Beginning", author="Unknown")
		@next_url = chap.nextch
		@title = title
		@author = author
		@chap = chap
		@body = ""
		@toc = "<h1>Table of Contents</h1>"
		@ind = 1
		until @next_url == false
			$stdout.puts @chap.title
			@next_url = @chap.nextch
			@body << "<h1 id=\"chapter#{@ind.to_s}\" class=\"chapter\">#{@chap.title}</h1>\n"
			@body << @chap.text + "\n"
			@toc  << "<a href=\"#chapter#{@ind}\">#{@chap.title}</a><br>\n"
			@ind  += 1
			if @next_url
				@chap = @chap.class.new @next_url
			end
		end
	end

	def full_text
		title = "<h1>#{@title}</h1 class=\"chap-title\">\n<i>#{Time.now.inspect}</i><br>\n"
		return title + @toc + @body
	end

	def write_to_file(fname="#{@title}.html")
		File.open fname, 'w' do |f| ; f.puts self.full_text;
		end
		@fname = fname
	end

	def convert_to_mobi
		@mobi = if @fname.include? "."
			@fname.gsub @fname.split(".").last, "mobi"
		else
			@fname + ".mobi"
		end
		system "ebook-convert #{@fname} #{@mobi} --title #{@title} --authors \"#{@author}\" --max-toc-link 600"
	end

	def html; @fname;
	end

	def mobi; @mobi;
	end
end

def publish(book, email, password, kindle)
	gmx_options = { :address              => "mail.gmx.com",
                :port                 => 587,
                :user_name            => email,
                :password             => password,
                :authentication       => 'plain',
                :enable_starttls_auto => true  }
	Mail.defaults do
		delivery_method :smtp, gmx_options
	end

	Mail.deliver do
	  to kindle
	  from email
	  subject ' '
	  add_file book.mobi
	end
end

url = start
ch1 = classFinder(url)
ch1 = ch1.new url
book = Book.new ch1, @book_title, author
book.write_to_file path + @book_title + ".html"
book.convert_to_mobi
publish book, email, password, kindle unless kindle.empty?