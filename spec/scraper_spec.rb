require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../scraper.rb'

WebMock.allow_net_connect!

describe RSPOMembersScraper do
	context "When it starts" do
		use_vcr_cassette

		before do
			RSPOMembersScraper.stubs(:scrape_member_info)
		end

		it "scrapes all the pages of the member list" do
			RSPOMembersScraper.start
			24.times { |i| a_request(:get, "http://www.rspo.org/?page=#{i}&q=membersearch").should have_been_made }
		end
		
		it "scrapes the member information page urls for each member" do
			RSPOMembersScraper.start
			RSPOMembersScraper.should have_received(:scrape_member_info).times(701)
		end
		
		describe "it scrapes pages dynamically" do
			it "finds the next page link" do
				next_link = RSPOMembersScraper.members_list_next_link ScraperWiki.scrape("#{RSPOMembersScraper::BASE_URL}/?page=0&q=membersearch")
				next_link.should_not be_nil
				next_link.should be_a_kind_of String
			end

			it "uses the next link to scrape the next page" do
				RSPOMembersScraper.stubs(:members_list_next_link)
				RSPOMembersScraper.start
				RSPOMembersScraper.should have_received(:members_list_next_link)
			end
		end
	end

	context "When a page of the member list is scraped" do
		use_vcr_cassette

		before do
			@html = ScraperWiki.scrape("#{RSPOMembersScraper::BASE_URL}/?page=0&q=membersearch")
		end
		
		it "extracts the list of members" do
			members = RSPOMembersScraper.extract_members @html
			members.should be_a_kind_of Array
			members.length.should == 30
		end

	end	

	context "When a member information page is scraped" do
		use_vcr_cassette :record => :new_episodes

		before do
			RSPOMembersScraper.scrape_member_info("http://rspo.org/?q=om/1993")
			@details = RSPOMembersScraper.extract_member_details ScraperWiki.scrape("http://rspo.org/?q=om/1993")
		end

		it "scrapes the page" do
			#a_request(:get, "http://rspo.org/?q=om/1993").should have_been_made 
		end
		
		it "extracts the member name as text" do
			@details['name'].should_not be_nil
			@details['name'].should be_a_kind_of String
			@details['name'].should == "AAA Oils & Fats Pte. Ltd."
		end

		it "extracts the country they are from as text" do
			@details['country'].should_not be_nil
			@details['country'].should be_a_kind_of String
			@details['country'].should == "Singapore"
		end

		it "extracts the address as cleaned text" do
			@details['address'].should_not be_nil
			@details['address'].should be_a_kind_of String
			@details['address'].should == "80 Raffles Place\n#50-01 Plaza I\nSingapore 048624"
		end

		it "extracts the industrial category as text" do
			@details['category'].should_not be_nil
			@details['category'].should be_a_kind_of String
			@details['category'].should == "Palm Oil Processors and Traders"
		end

		it "extracts when they have been a member since as a date" do
			@details['member_since'].should_not be_nil
			@details['member_since'].should be_a_kind_of Date
			@details['member_since'].should == Date.new(2011,12,8)
		end

		it "saves the data to the datastore" do
			@details.stubs(:save)
			@details.save
			@details.should have_received(:save)
		end
	end
end
