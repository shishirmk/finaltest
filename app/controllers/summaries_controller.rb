class SummariesController < ApplicationController
  #before_filter :compute_tweets, :only => [:alltweets]
  skip_before_filter :verify_authenticity_token
  
  protected
  def compute_tweets
    if params[:username]
      username = session[:username] 
      computed_tweets = ComputedTweets.get_tweets(username)
      session[:computed_tweets] = computed_tweets
    end
  end
   public
  # GET /summaries
  # GET /summaries.json
  def index
    render action:"new"
  end

  # GET /summaries/1
  # GET /summaries/1.json
  def show
    @summary = Summary.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @summary }
    end
  end

  # GET /summaries/new
  # GET /summaries/new.json
  def new
    respond_to do |format|
      format.html # new.html.erb
      #format.json { render json: @summary }
    end
  end

  # GET /summaries/1/edit
  def edit
    @summary = Summary.find(params[:id])
  end
  
  def alltweets
    if params[:fetch] == "online"
      GetTweets.store_tweets_of_user(params[:username])
    end
    tweets = GetTweets.get_tweets_of_user(params[:username])
    unique_tweets = GetTweets.remove_retweets(tweets) #removes only retweets
    @tweets = GetTweets.get_tweet_text(unique_tweets) #removes copy tweets which are not retweets
    @username = params[:username]
    session[:username] = params[:username]
    session[@username+"_tweets"] = @tweets
  end

  def manualsummary
    tweet_list = Array.new
    for tweet in params[:tweets]
      tweet_list << tweet
    end
    @username = session[:username]
    session[@username+"_chosen"] = tweet_list
    GetTweets.store_manual_tweets(params[:username],tweet_list)
    redirect_to :action => "showmanual"
  end
  
  def showmanual
    @username = session[:username]
    @computed_tweets = ComputedTweets.get_em_tweets(@username)
    session[@username+"_computed_em"] = @computed_tweets
    @all_tweets = session[@username+"_chosen"]
  end

  def showmanual1
    @username = session[:username]
    session[@username+"_computed_em_general_score"] = params[:general_score]
    session[@username+"_computed_em_topic_score"] = params[:topic_score]
    session[@username+"_computed_em_comments"] = params[:comments]
    @username = session[:username]
    @computed_tweets = ComputedTweets.get_sat_tweets(@username)
    session[@username+"_computed_sat"] = @computed_tweets
    @all_tweets = session[@username+"_chosen"]
    render 'showmanual1'
  end

  def thanks
    @username = session[:username]
    session[@username+"_computed_sat_general_score"] = params[:general_score]
    session[@username+"_computed_sat_topic_score"] = params[:topic_score]
    session[@username+"_computed_sat_comments"] = params[:comments]
    REDIS.rpush "results",session.to_json
    render 'thanks'
  end

  # PUT /summaries/1
  # PUT /summaries/1.json
  def update
    @summary = Summary.find(params[:id])

    respond_to do |format|
      if @summary.update_attributes(params[:summary])
        format.html { redirect_to @summary, notice: 'Summary was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @summary.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /summaries/1
  # DELETE /summaries/1.json
  def destroy
    @summary = Summary.find(params[:id])
    @summary.destroy

    respond_to do |format|
      format.html { redirect_to summaries_url }
      format.json { head :ok }
    end
  end
end
