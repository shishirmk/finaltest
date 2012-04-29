require 'Main'
require 'SimpleCluster'
require 'XmeansCluster'
module ComputedTweets
  def self.get_em_tweets(twitter_username)
    #GetTweets.store_tweets_of_user(params[:username])
    tweets = GetTweets.get_tweets_of_user(twitter_username)
    unique_tweets = GetTweets.remove_retweets(tweets) #removes only retweets
    tweet_text_array = GetTweets.get_tweet_text(unique_tweets) #removes copy tweets which are not retweets
    tweet_text_array_copy = tweet_text_array.clone()
    File.open("Inputs/"+twitter_username+".txt","w") do |f|
      for tweet in tweet_text_array_copy
        f << tweet+"\n"
      end
    end
    m = Main.new
    summ_tweets = m.main_function(twitter_username,"file","kmeans")
    return summ_tweets
  end

  def self.get_sat_tweets(twitter_username)
    #GetTweets.store_tweets_of_user(params[:username])
    tweets = GetTweets.get_tweets_of_user(twitter_username)
    unique_tweets = GetTweets.remove_retweets(tweets) #removes only retweets
    tweet_text_array = GetTweets.get_tweet_text(unique_tweets) #removes copy tweets which are not retweets
    tweet_text_array_copy = tweet_text_array.clone()
    File.open("Inputs/"+twitter_username+".txt","w") do |f| 
      for tweet in tweet_text_array_copy
        f << tweet+"\n"
      end 
    end 
    m = SimpleCluster.new
    summ_tweets = m.cluster_it(twitter_username,"file")
    return summ_tweets
  end
  
  def self.get_xmeans_tweets(twitter_username)
    tweets = GetTweets.get_tweets_of_user(twitter_username)
    unique_tweets = GetTweets.remove_retweets(tweets) #removes only retweets
    tweet_text_array = GetTweets.get_tweet_text(unique_tweets) #removes copy tweets which are not retweets
    tweet_text_array_copy = tweet_text_array.clone()
    File.open("Inputs/"+twitter_username+".txt","w") do |f| 
      for tweet in tweet_text_array_copy
        f << tweet+"\n"
      end 
    end 
    m = XmeansCluster.new
    summ_tweets = m.cluster_it(twitter_username,"file")
    puts summ_tweets.to_s
    return summ_tweets
  end
end
