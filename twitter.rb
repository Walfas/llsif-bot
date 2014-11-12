require 'twitter'
require 'yaml'

require_relative 'llsif_card'

@config ||= YAML.load_file 'config.yml'

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

def tweet_card
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

tweet_card

