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
          nouns_list << w.word if w.pos.match(/^NN.*/)
        end
        temp << nouns_list.join(" ")
        i += 1
        csv << temp
      end
    end
  end

end
