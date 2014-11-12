require 'json'
require 'mini_magick'
require 'net/http'
require 'uri'
require 'yaml'

module LlsifCard
  @config ||= YAML.load_file 'config.yml'

  module_function

  # Pick a random image in the img directory
  def get_random_image_path dir
    Dir[dir + '/**/*.{png,jpg,jpeg,gif}'].sample
  end

  def get_random_word url, params
    uri = URI.parse url
    uri.query = URI.encode_www_form params
    body = Net::HTTP.get uri
    json = JSON.parse body
    json['word']
  end

  def overlay_text img, text, options
    stroke_color = '#' + options['stroke_color']
    font = options['font']
    w, h = options['width'], options['height']

    img.combine_options do |i|
      i.resize "#{w}x#{h}"

      # Blur out the name
      i.region '30x300+18+84'
      i.blur '0x5'
      i.region.+

      # Set options
      i.font options['font']
      i.pointsize '28'
      i.kerning '3.15'
      i.strokewidth '4.5'

      draw_command = ->(x,y) do
        "translate #{w},0 rotate -90 gravity NorthEast text #{-y},#{-x} '#{text}'"
      end

      # Outline, slightly offset
      i.stroke stroke_color
      i.fill stroke_color
      i.draw draw_command.call(25, 77)

      # Fill
      i.stroke 'none'
      i.fill 'white'
      i.draw draw_command.call(25, 79)
    end
  end

  def generate_card! input_path, output_path
    img = MiniMagick::Image.open input_path

    adjective = get_random_word @config['wordnik']['url'], @config['wordnik']['params']
    noun = 'Student'
    student_name = "#{adjective.capitalize} #{noun}"

    overlay_text img, student_name.upcase, @config['imagemagick']

    format = output_path.split('.')[-1] # Check format (jpg, png, etc)
    img.format format
    img.write output_path

    student_name
  end
end

