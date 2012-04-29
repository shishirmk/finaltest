# coding: utf-8
require 'redis'
require 'json'
require 'rubygems'

#User Defined
require 'TFIDFWrapper'
require 'RedisWrapper'
require 'FileWrapper'
require 'PrintData'
require 'TwitterWrapper'
require 'Word'
require 'NLP'
require 'rarff'
require 'csv'
#Extending class array with a sum function.
module Enumerable

    def sum 
      self.inject(0){|accum, i| accum + i } 
    end 

    def mean
      self.sum/self.length.to_f
    end 

    def sample_variance(mean)
      return 1/0.0 if self.length <= 1
      m = mean || self.mean
      sum = self.inject(0){|accum, i| accum +(i-m)**2 }
      sum/(self.length - 1).to_f
    end 

    def standard_deviation(mean)
      return Math.sqrt(self.sample_variance(mean))
    end

end
class SimpleCluster
def euclidean_distance(a,b,start,finish)
  a1 = a[start,finish]
  b1 = b[start,finish]
  
  sum = 0 
  a1.length.times do |i| 
    diff = a1[i].to_i - b1[i].to_i
    sum += diff**2
  end 
  
  return Math.sqrt(sum)
end

#The main function 
def cluster_it(username,source)

  puts username
  #Assigning command line variables
  tweets = Array.new

  if source == "twitter"
    #Get user tweets from twitter
    twitter = TwitterWrapper.new
    tweets_json = twitter.user_tweets(username,100)
    tweets = twitter.json_to_tweets(tweets_json)
  elsif source == "redis"
    redis = RedisWrapper.new
    tweet_list = redis.redis_client.lrange username+"_tweets", 0, -1
    tweet_list.each do |t|
      tweets.push(JSON.parse(t)['text'])
    end

    chosen_lists = redis.redis_client.lrange "chosen_"+username+"_tweets", 0 , -1
    user_tweets_file = File.new("Inputs/User_Tweets.txt","w+")
    for list in chosen_lists
      user_tweets_file << JSON.parse(list).join("\n")
      user_tweets_file << "\n\n"
    end
  else
   #Get tweets from a file in Inputs folder 
    twitter = FileWrapper.new()
    twitter.filename = "Inputs/"+username+".txt"
    tweets = twitter.get_tweets
  end

  #Filter retweets and reply. Just remove them from the list of tweets
  tweets = tweets.delete_if {|tweet| tweet.is_reply? or tweet.is_retweet?}
  puts "Tweets Returned Just fine" if !tweets.nil?


  #Populating the word array of each tweet
  tfidf = TFIDFWrapper.new(tweets)
  tweet_index = 0
  max = tweets.length #Highest proximity number possible.
  for tweet in tweets
      idf_array = tfidf.idf_sentence(tweet.processed_tweet)
      pos_array = NLP.pos_sentence(tweet)
      i = 0 #Number of words
      tweet.processed_tweet.split().uniq.each do |w|
        temp = Word.new
        temp.word = w
        temp.idf = idf_array[i]
        temp.pos = pos_array[i]
        tweet.word_array << temp
        i += 1
      end
    #Updating stuff in the loop
    tweet_index += 1 #To maintain the tweet number for proximity.
  end
  PrintData.print_simple_csv(tweets,"tmp/#{username}_data.csv")
  output =  %x{ java -classpath "/research/weka/weka-3-7-5/weka.jar"  weka.core.converters.CSVLoader "tmp/#{username}_data.csv" > "tmp/tmp.arff"; java -classpath "/research/weka/weka-3-7-5/weka.jar" weka.filters.unsupervised.attribute.NominalToString -C last -i "tmp/tmp.arff" -o "tmp/tmp1.arff"; java -classpath "/research/weka/weka-3-7-5/weka.jar" weka.filters.unsupervised.attribute.StringToWordVector -R last -i "tmp/tmp1.arff" -o "tmp/tmp2.arff"; java -classpath "/research/weka/weka-3-7-5/weka.jar" weka.core.converters.CSVSaver -i "tmp/tmp2.arff" -o "tmp/tmp3.csv"}
self.simple_cluster("tmp/tmp3.csv")  
end

def simple_cluster(filename)
  all_rows = Array.new
  CSV.foreach(filename,{:quote_char => '"'}) do |row|
    all_rows << row
  end
  all_rows.delete_at(0)

  upper_limit = all_rows[0].length - 1
  all_rows.length.times do |i|
    score = 0
    for b in all_rows
      score += self.euclidean_distance(all_rows[i],b,2,upper_limit)
    end
    #puts "#{i} #{score} #{all_rows[i].length}"
    all_rows[i] << score
  end

  all_rows.sort!{|a,b| a[-1] <=> b[-1]}
  summary_list = Array.new
  summary_list << all_rows[0]
  all_rows.delete_at(0)


  count = 0
  while count <  (all_rows.length*0.1).round()
    max = 0
    candidate = nil
    for r1 in all_rows
      score = 0
      for s1 in summary_list
        score += self.euclidean_distance(r1,s1,2,upper_limit)
      end
      if score > max
        max = score
        candidate = r1
      end
    end
    summary_list << candidate
    all_rows.delete(candidate)
    count += 1
  end

  summ_array = Array.new
  for s1 in summary_list
    puts s1[1]
    summ_array << s1[1].parse_csv[0]
  end
  return summ_array

end
end
