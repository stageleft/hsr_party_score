require 'open-uri'
require 'cairo'
require 'json'

class ScoreCard
#    def initialize(width: 2000, height: 1794*8)
    def initialize(width: 500, height: 394)
        # @domain   = "https://github.com/Mar-7th/StarRailRes/blob/master/"
        @domain     = "https://raw.githubusercontent.com/Mar-7th/StarRailRes/refs/heads/master/"
        @width      = width
        @height     = height
        @font       = "Sans-serif"
        @pointsize  = 16
    end

    def download_image(url, output_path)
        if !FileTest.exist?(output_path) then
            URI.open(url) do |image|
                File.open(output_path, 'wb') do |file|
                    file.write(image.read)
                end
            end
        end
    end
    def generate(input_json = "{}", output_path = "scorecard.png")
        param = JSON.parse(input_json)

        surface = Cairo::ImageSurface.new(@width, @height)
        context = Cairo::Context.new(surface)

        player_id = "#{param["player"]["uid"]}"
puts player_id
        context.move_to(100, 150)
        context.set_font_size(@pointsize)
        context.set_source_rgb(255,255,255)
        context.show_text("ID: #{player_id}")

        player_name = "#{param["player"]["nickname"]}"
puts player_name
        context.move_to(150, 200)
        context.select_font_face("IPAPGothic",
                    Cairo::FONT_SLANT_NORMAL,
                    Cairo::FONT_WEIGHT_NORMAL)
        context.show_text("Name: #{player_name}")

#        player_icon_url = "#{@domain}#{input_json["player"]["avatar"]["icon"]}"
        player_icon_path = "#{param["player"]["avatar"]["icon"]}"
puts player_icon_path
        player_icon_url = "#{@domain}#{param["player"]["avatar"]["icon"]}"
puts player_icon_url
        download_image(player_icon_url, player_icon_path)
        context.set_source(Cairo::ImageSurface.from_png(player_icon_path), 0, 0)
        context.paint

        surface.write_to_png(output_path)
    end
end