require 'DataPoint'
require 'csv'

class PrintData

 def self.print_simple_csv(tweets,filename)
    CSV.open(filename, "wb",{:force_quotes => true}) do |csv|
      temp = Array.new
      temp << "serial_number"
      temp << "original_tweet"
      temp << "nouns_only"
      csv << temp
     
      i = 1 
      tweets.each do |tweet|
        temp = Array.new
        temp << i
        temp << tweet.original_tweet.gsub(/[",]+/,"")
        nouns_list = Array.new
        tweet.word_array.each do |w| 
          nouns_list << w.word #if w.pos.match(/^NN.*/)
        end 
        temp << nouns_list.join(" ")
        i += 1
        csv << temp
      end 
    end 
  end 

	#Printing csv to the files.
	def self.print_csv(datapoints,filename,user_tweets_list)
		CSV.open(filename, "wb",{:force_quotes => true}) do |csv|
      temp = Array.new
      temp << "original_tweet"
      temp << "total_words"
      temp << "total_sentiment"
      temp << "total_nouns"
      temp << "total_users"
			csv << temp
      datapoints.each do |dp|
				temp = Array.new
				temp << dp.original_tweet.gsub(/[",]+/,"")
				temp << dp.original_tweet.split(/\s+/).length
        total_sentiment = dp.word_array.inject(0) do |result,word| 
          if !word.pos.match(/^NN.*/)
            result + word.sentiment.abs
          end
        end
        temp << total_sentiment
        total_nouns = dp.word_array.inject(0) do |result,word| 
          if word.pos.match(/^NN.*/)
            result + 1
          else
            result + 0
          end
        end
        temp << total_nouns
        total_users = user_tweets_list.inject(0) do |result,tweets|
          if tweets.index(dp.original_tweet)
            result + 1
          else
            result + 0
          end
        end
        temp << total_users
				csv << temp 
			end
		end
	end


end
