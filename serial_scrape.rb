require 'nokogiri'
require 'open-uri'

@title = ""
@toc = ""
@text = ""

class Chapter
	def initialize(url)
		@doc = Nokogiri::HTML open url
		@url = url
	end
	def title ;		@doc.css("h1").first.content ; end
	def text ; 		@doc.css("p"); end
	def linksearch(pattern)
		find = false
		links = @doc.css "a"
		links.each do |l|
			if l.content.upcase.include?(pattern)
				find = l["href"]
			end
		end
		unless find[0..3] == "http"
			domain_index = @url.index("/",8)
			find = @url[0..domain_index-1] + find
		end
		return find
	end
	def nextch;		self.linksearch("NEXT"); end
	def prevch;		self.linksearch("PREV"); end
end

def Book(title, first_chapter_url)


url = 'https://www.royalroad.com/fiction/25225/delve/chapter/410382/50-baggage'
url = 'https://www.parahumans.net/2019/09/14/from-within-16-10/'
ch = Chapter.new(url)
puts ch.prevch
puts ch.nextch
puts ch.title
File.open 'misc.html', 'w' do |f|
	f.puts Chapter.new(url).text
end