require_relative 'twitter'

task :tweet do
  LlsifTweet::tweet_card!
end

task :update_profile do
  LlsifTweet::update_profile!
end

SECONDS_PER_HOUR = 3600
task :tumble do
  require_relative 'tumblr'

  day = Time.now.to_date.prev_day

  start_time = day.to_time
  end_time = start_time + SECONDS_PER_HOUR*24

  tweets = LlsifTweet::top_tweets 9, start_time, end_time
  files = LlsifTweet::get_files tweets
  img_paths = files.map(&:path)

  pre = "<p>Students for <strong>#{day.to_s}</strong></p>\n"
  html = LlsifTweet.to_html tweets

  LlsifTumble::photoset img_paths, (pre + html)
end

