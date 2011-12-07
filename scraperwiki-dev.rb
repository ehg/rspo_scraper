module ScraperWiki
	class << self
		def save_sqlite_stub(index=[], data=[], tbl_name='swdata')
			p data if show_data?
		end

		def show_data?
			SHOW_DATA
		rescue NameError
			false
		end

		alias original_save_sqlite save_sqlite
		alias save_sqlite save_sqlite_stub
	end
end


