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
class XmeansCluster
  def cluster_it(username,source)
    
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

  #Filter all tweets if they have word_array as nil
  all_points = Array.new
  i = 0 
  tweets.each do |tweet|
    if tweet.word_array.length >= 3
      t = Point.new(tweet) 
      all_points << t 
      i += 1
    end 
  end 
  input_tweets = all_points.clone


PrintData.print_simple_csv(tweets,"tmp/#{username}_data.csv")
output =  %x{ java -classpath "/research/weka/weka-3-7-5/weka.jar"  weka.core.converters.CSVLoader "tmp/BarackObama_data.csv" > "tmp/tmp.arff"; java -classpath "/research/weka/weka-3-7-5/weka.jar" weka.filters.unsupervised.attribute.NominalToString -C last -i "tmp/tmp.arff" -o "tmp/tmp1.arff"; java -classpath "/research/weka/weka-3-7-5/weka.jar" weka.filters.unsupervised.attribute.StringToWordVector -R last -i "tmp/tmp1.arff" -o "tmp/tmp2.arff"; java -classpath "/research/weka/weka-3-7-5/weka.jar:/home/shishirmk/wekafiles/packages/XMeans/XMeans.jar" weka.filters.unsupervised.attribute.AddCluster  -i "tmp/tmp2.arff" -o "tmp/out.arff"  -W "weka.clusterers.XMeans" }
print output
wk = WekaWrapper.new
wk.get_clusters(all_points)
final_clusters = Clusterer.map_to_clusters(all_points)
return Summary.simple_summary(final_clusters)

  end
end
