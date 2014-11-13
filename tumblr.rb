require 'tumblr_client'

module LlsifTumble
  @config ||= YAML.load_file 'config.yml'

  module_function
  def client
    return @client if @client

    c = @config['tumblr']
    Tumblr.configure do |conf|
      conf.consumer_key = c['api']['consumer_key']
      conf.consumer_secret = c['api']['consumer_secret']
      conf.oauth_token = c['api']['oauth_token']
      conf.oauth_token_secret = c['api']['oauth_token_secret']
    end

    @client = Tumblr::Client.new client: :httpclient
  end

  def photoset images, body
    host = @config['tumblr']['host']

    # https://groups.google.com/forum/#!topic/tumblr-api/DoDWO-K0p4c
    photoset_layout = images.each_slice(3).to_a.map(&:length).join

    params = {
      data: images,
      caption: body,
      photoset_layout: photoset_layout,
      tags: @config['tumblr']['tags']
    }

    client.photo host, params
  end
end

