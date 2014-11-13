require_relative 'twitter'

task :tweet do
  LlsifTweet::tweet_card!
end

task :update_profile do
  LlsifTweet::update_profile!
end

task :tumble do
  require_relative 'tumblr'

  day = DateTime.now.to_date.prev_day.to_s

  tweets = LlsifTweet::top_tweets 9, 24
  files = LlsifTweet::get_files tweets
  img_paths = files.map(&:path)

  pre = "<p>Students for <strong>#{day}</strong></p>\n"
  html = LlsifTweet.to_html tweets

  LlsifTumble::photoset img_paths, (pre + html)
end

