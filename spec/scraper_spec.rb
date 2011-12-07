require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../scraper.rb'

WebMock.allow_net_connect!

describe RSPOMembersScraper do
	context "When it starts" do
		use_vcr_cassette

		before do
			member = { 'name' => 'test', 'country' => 'Singapore'}
			RSPOMembersScraper.stubs(:scrape_member_info).returns member 
		end

		it "scrapes all the pages of the member list" do
			RSPOMembersScraper.start
			24.times do |i| 
				a_request(:get, 
									"http://www.rspo.org/?page=#{i}&q=membersearch"
								 ).should have_been_made 
			end
		end
		
		it "scrapes the member information page urls for each member" do
			RSPOMembersScraper.start
			RSPOMembersScraper.should have_received(:scrape_member_info).times(701)
		end
		
		describe "it scrapes pages dynamically" do
			it "finds the next page link" do
				html = ScraperWiki.scrape("#{RSPOMembersScraper::BASE_URL}/?page=0&q=membersearch")
				next_link = RSPOMembersScraper.members_list_next_link html
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
			@members_array = RSPOMembersScraper.members
			@members_array.stubs(:save)
			@members = RSPOMembersScraper.extract_members @html
		end
		
		it "extracts the list of members" do
			@members.should be_a_kind_of Array
			@members.length.should == 30
		end
	
		it "saves the data (if any) to the datastore" do
			@members_array.save
			@members_array.should have_received(:save)
		end
	end	

	context "When a member information page is scraped" do
		use_vcr_cassette :record => :new_episodes

		context "When all fields exist in the HTML" do
			before do
				@details = RSPOMembersScraper.scrape_member_info("http://rspo.org/?q=om/1993")
				RSPOMembersScraper.add_to_members_array @details
			end

			it "scrapes the page" do
				a_request(:get, "http://rspo.org/?q=om/1993").should have_been_made 
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
				@details['member_since'].should == Date.new(2011,8,12)
			end
		end

		context "when fields aren't present in HTML" do
				before do
					@details = RSPOMembersScraper.scrape_member_info("http://rspo.org/?q=om/1985")
					@details['name'] = "A test name"
				end

				it "doesn't add it to the members array if there's no name" do
					@details['name'] = nil
					RSPOMembersScraper.add_to_members_array @details
					RSPOMembersScraper.members.should_not include @details
				end

				it "adds it to the members array even if there's no country" do
					RSPOMembersScraper.add_to_members_array @details
					RSPOMembersScraper.members.should include @details
				end

				it "adds it to the members array even if there's no address" do
					RSPOMembersScraper.add_to_members_array @details
					RSPOMembersScraper.members.should include @details
				end

				it "adds it to the members array even if there's no category" do
					RSPOMembersScraper.add_to_members_array @details
					RSPOMembersScraper.members.should include @details
				end
				
				it "adds it to the members array even if there's no member since date" do
					RSPOMembersScraper.add_to_members_array @details
					RSPOMembersScraper.members.should include @details
				end
		end

		after do
			RSPOMembersScraper.members.clear
		end
	end
end
