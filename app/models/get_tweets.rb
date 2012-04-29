module GetTweets

  def self.store_tweets_of_user(twitter_username)
      Twitter.configure do |config|
        config.consumer_key = "6bhkH5O07MWzxcQDjsqPA"
        config.consumer_secret = "EY2IDBlnDlv8jfZBmjQoT0aNfnL3RQiOJ5JD7EvJyp0"
        config.oauth_token = "17571156-9JHLthIo5A3lrVmAVr9Wz6VDgf6avsPUGa1kef4SH"
        config.oauth_token_secret = "ZxkwqXoX0c4m42i4gBUzLZ8LJLZJhF16x39SoTcs"
      end
      tryagain = true
      while tryagain
  begin
    whole_timeline_json = Twitter.user_timeline(twitter_username,{count: 70, exclude_replies: true, include_rts: false})
    tryagain = false
  rescue
    tryagain = true
  end
      end
      all_tweets = Array.new
      whole_timeline_json.each  do |tweet|
    if tweet.in_reply_to_screen_name == nil
      all_tweets << tweet
    end
      end
      #puts all_tweets.length
      json_string = all_tweets.to_json()
      tweets = JSON.parse(json_string)
      main_key = twitter_username+"_tweets"
      #redis = Redis.new()
      RedisMod.conn.del(main_key)
      #puts tweets.length
      tweets.each do |tweet|
    RedisMod.conn.rpush main_key, tweet.to_json
      end
  end
  
  def self.store_manual_tweets(twitter_username,manual_tweets)
    main_key = "chosen_"+twitter_username+"_tweets"
    RedisMod.conn.rpush main_key, manual_tweets.to_json
  end
  
  def self.get_manual_tweets(twitter_username)
    main_key = "chosen_"+twitter_username+"_tweets"
    len = RedisMod.conn.llen main_key
    tweet_list_list = RedisMod.conn.lrange main_key,0, len-1
    result_array = Array.new
    for tweets_string in tweet_list_list
      tweets = Array.new
      tweet_list = JSON.parse(tweets_string)
      tweet_list.each do |t|
  tweets.push(t)
      end
      result_array << tweets
    end
    return result_array
  end
  
  def self.get_tweets_of_user(twitter_username)
    main_key = twitter_username+"_tweets"
    len = RedisMod.conn.llen main_key
    tweet_list = RedisMod.conn.lrange main_key,0, len-1
    tweets = Array.new
    tweet_list.each do |t|
      tweets.push(JSON.parse(t))
    end
    return tweets
  end
  
  def self.remove_retweets(tweet_array)
    retweets_index = Array.new
    for i in 0..tweet_array.length-1
  if tweet_array[i]['retweeted_status'] != nil or tweet_array[i]['text'] =~ /RT(.*)/
      retweets_index.push(i)
  end
    end
    for i in 0..retweets_index.length-1
  tweet_array.delete_at(retweets_index.pop())
    end    
    return tweet_array  
  end

  def self.stem_tweets(tweets_array)
    for i in 0..tweets_array.length - 1
  temp_tweet = tweets_array[i].split()
  for j in 0..temp_tweet.length - 1
      temp_tweet[j] = temp_tweet[j].gsub(/[[:punct:]]/,'').strip().downcase().stem()
  end
  tweets_array[i] = temp_tweet.join(' ')
    end
    return tweets_array
  end
  
  def self.get_tweet_text(full_tweets)
    tweet_text_hash = Hash.new
    for i in 0..full_tweets.length-1
      tweet_text_hash[full_tweets[i]['text']] = 1
    end
    return tweet_text_hash.keys
  end
  
  def self.create_tfidf_model(tweet_text_array_copy)
    tfidf_model = TfIdf.new()
    for i in 0..tweet_text_array_copy.length - 1
      tfidf_model.add_input_document(tweet_text_array_copy[i])
    end
    return tfidf_model
  end
  
  def self.calculate_idf(tfidf_model,tweet_text_array_copy)
    vector_array = Array.new
    j = 0
    for i in 0..tweet_text_array_copy.length - 1
      temp = Array.new
      twit = tweet_text_array_copy[i].split()
      for k in 0..twit.length - 1
  temp1 = Array.new 
  temp1[0] = twit[k]
  temp1[1] = tfidf_model.idf(twit[k])
  temp << temp1
      end
      temphash = Hash.new
      temp.each do |vec|
      temphash[vec[0]] = vec[1]
      end
      if temphash.length == 0 
  next
      end
      vector_array[j] = temphash
      j = j + 1
    end
    return vector_array
  end
  
  def self.check_criteria(w,lower_limit,upper_limit)
    if w.idf <= lower_limit or w.idf >= upper_limit
      return 0
    else
      return 1
    end
  end

  #creating a hash of all the words and the tweet numbers they occur in
  def self.get_glossary_hash(vector_array)
    glossary_hash = Hash.new
    i = 1
    stop_words = StopWords.get_stopwords()
    for vec in vector_array
      for key in vec
  if stop_words.index(key[0]) != nil
    next
  end
  if glossary_hash[key].nil?
    temp = Array.new
    temp << i
    glossary_hash[key] = temp
  else
    temp = glossary_hash[key]
    temp << i
    glossary_hash[key] = temp
  end
      end
      i = i + 1
    end
    return glossary_hash
  end

  def self.get_idf_limits(glossary_hash)
      #getting all the idf values
      idf_vals = Array.new
      for k in glossary_hash.keys
  idf_vals << k[1]
      end
      
      fq_ratio = 0.1
      tq_ratio = 0.7
      #get the first quartile
      idf_vals.sort!
      fq_index = (fq_ratio)*(idf_vals.length + 1)
      tq_index =  (tq_ratio)*(idf_vals.length + 1)
      fq_idf = idf_vals[fq_index.floor]
      tq_idf = idf_vals[tq_index.floor]
      fq_idf = 1
      tq_idf = 4
      return [fq_idf,tq_idf]
  end

  def self.get_word_list(glossary_hash,vector_array)
      word_list = Array.new
      for k in glossary_hash.keys
  i = 0
  while i < glossary_hash[k].length
    if i == 0
      temp = Word.new(k[0],k[1].round(4),glossary_hash[k][i],0)
    else
      dist = glossary_hash[k][i]-glossary_hash[k][i-1]
      #The all important code that decides the importance of a tweet.
      calcval = ((1/k[1])*vector_array.length)**-(dist.abs)
      temp = Word.new(k[0],k[1].round(4),glossary_hash[k][i],calcval.round(6))
    end
    i = i + 1
    word_list << temp
  end
      end
      return word_list
  end

  def self.process_word_list(word_list,min_cluster_index,min_cluster_size,reject_tweet_no)
      #Filtering based on adjacent words in the word_list
      #This for loop assumes that the ordering is in the same way it was created that is grouped by spelling, then sorted by tweet_no
      i = 0
      while i < word_list.length
  if word_list[i].cluster_index > min_cluster_index
    j = i 
    while word_list[j].cluster_index > min_cluster_index
      j = j + 1
    end
    if j - i < min_cluster_size
      k = i
      while k < j
    word_list[k].tweet_no = reject_tweet_no
    k = k + 1
      end
    end
    i = j
  else
    word_list[i].tweet_no = reject_tweet_no
    i = i + 1
  end
      end
      return word_list
  end

end
