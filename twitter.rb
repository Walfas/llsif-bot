require 'twitter'
require 'open-uri'
require 'yaml'

require_relative 'llsif_card'

module LlsifTweet
  @config ||= YAML.load_file 'config.yml'

  module_function

  def client
    return @client if @client

    c = @config['twitter']['api']
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key = c['consumer_key']
      config.consumer_secret = c['consumer_secret']
      config.access_token = c['access_token']
      config.access_token_secret = c['access_token_secret']
    end
  end

  def random_phrase_from_file filename
    File.readlines(filename).reject(&:empty?).sample.gsub "\n", ''
  end

  def tweet_card!
    img_path = LlsifCard.get_random_image_path @config['general']['images_path']
    #character_name = img_path.split('/')[-2]

    out_path = @config['general']['output_path']
    student_name = LlsifCard.generate_card! img_path, out_path
    file = open out_path

    phrase = random_phrase_from_file @config['general']['phrases_path']
    tweet_text = %Q{"#{phrase}"\n- #{student_name}}

    tweet = begin
      client.update_with_media tweet_text, file
    rescue Twitter::Error::RequestTimeout
      sleep 30
      retry
    end
  end

  SECONDS_IN_HOUR = 3600
  def top_tweets n=9, hours_ago=24
    tweets = client.user_timeline count: 200, exclude_replies: true
    tweets_by_time = tweets.select { |t| (Time.now - t.created_at) < SECONDS_IN_HOUR*hours_ago }
    sorted = tweets_by_time.sort_by { |t| -t.favorite_count-t.retweet_count }
    sorted.take n
  end

  def update_profile!
    tweet = top_tweets(1, @config['general']['profile_lookback_hours']).first

    student_name = tweet.text.match(/- (.* Student)/).captures.first

    # If profile info is the same, don't bother
    user = client.user skip_status: true
    return if user.name == student_name

    change_display_name student_name if student_name

    img_url = tweet.media.first.media_url unless tweet.media.empty?
    change_profile_pic img_url if img_url
  end

  def change_profile_pic url
    file = open url

    client.update_profile_image file
  end

  def change_display_name name
    client.update_profile name: name[0...20] # Name can have a max length of 20
  end

  def get_files tweets
    tweets.flat_map { |t| open(t.media.first.media_url.to_s) unless t.media.empty?}
  end

  def to_html tweets
    text = tweets.map.with_index do |t, index|
      total = t.favorite_count + t.retweet_count
      count = "<strong>#{total}</strong>"
      count_details =  "#{t.retweet_count} RTs + #{t.favorite_count} Favs"

      "<p>#{index+1}. #{t.text}</p>\n<blockquote>Bond: #{count} (#{count_details})</blockquote>"
    end.join("\n")

    text
  end
end

