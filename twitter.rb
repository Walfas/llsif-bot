require 'twitter'
require 'open-uri'
require 'yaml'

require_relative 'llsif_card'

module LlsifTweet
  @config ||= YAML.load_file 'config.yml'

  module_function

  def client
    return @client if @client

    c = @config['twitter']
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
    character_name = img_path.split('/')[-2]

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

  def top_tweets n=9, day=DateTime.now.to_date.prev_day
    tweets = client.user_timeline count: 200, exclude_replies: true
    tweets_by_day = tweets.select { |t| t.created_at.to_date == day }
    sorted = tweets_by_day.sort_by { |t| -t.favorite_count-t.retweet_count }
    sorted.take n
  end

  def update_profile!
    tweet = top_tweets(1).first

    student_name = tweet.text.match(/- (.* Student)/).captures.first
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
end

