require 'scraperwiki'
require 'nokogiri'

class RSPOMembersScraper
	BASE_URL = "http://www.rspo.org"

	def self.start
		scrape_member_list "#{BASE_URL}/?page=0&q=membersearch"
	end

	def self.scrape_member_list(url)
		html = ScraperWiki.scrape url
		until (next_link = members_list_next_link(html)).nil?
			html = ScraperWiki.scrape "#{BASE_URL}#{next_link}"
			members = extract_members html
			members.each { |m| scrape_member_info(m) }
		end
	end

	def self.members_list_next_link(html)
		doc = Nokogiri::HTML html
	 	link = doc.search(".pager-next a").first
		return nil if link.nil?
		link.attr(:href)
	end

	def self.extract_members(html)
		links = []
		doc = Nokogiri::HTML html
		member_rows = doc.search "table.views-table tbody tr"
		member_rows.each do |row|
			link = row.search(".views-field-field-name-value a").first
			links << "#{BASE_URL}#{link.attr(:href)}"
		end
		links
	end

	def self.scrape_member_info(url)
		html = ScraperWiki::scrape url
	end

	def self.extract_member_details(html)
		member = Member.new
		doc = Nokogiri::HTML html
		member['name'] = doc.search("div#main-inner2 div.inner h1.title").first.text
		country_node = doc.search("div.field-field-country").first
		country_node.search(".field-label-inline-first").first.remove
		member['country'] = country_node.text.strip
		
		address_nodes = doc.search("div.field-field-address .field-item p")
		member['address'] = address_nodes.inject("") { |lines, line| lines << line.text + "\n" }
		member['address'].strip!
		
		category_node = doc.search("div.field-field-category").first
		category_node.search(".field-label-inline-first").first.remove
		member['category'] = category_node.text.strip
		
		member['member_since'] = Date.parse doc.search(".field-field-approved-date .date-display-single").first.text
		member
	end

	class Member < Hash
		def save
			ScraperWiki::save_sqlite ['name'], self
		end
	end
end
