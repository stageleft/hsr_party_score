# ScoreCardAnyCell
# A cell that can contain an image and multi-line text.
# [       ] multi-line text
# [1 image] multi-line text
# [       ] multi-line text
class ScoreCardAnyCell
    def initialize(image_path: "", text_array: [""])
        # setup image
        @domain     = "https://raw.githubusercontent.com/Mar-7th/StarRailRes/refs/heads/master/"
        url = "#{@domain}#{image_path}"
        download_image(url, image_path)
        @image = Cairo::ImageSurface.from_png(image_path)
        # setup text context
        @context = Cairo::Context.new(@image)
        @context.set_font_size(16)
        @context.select_font_face("IPAPGothic",
                    Cairo::FONT_SLANT_NORMAL,
                    Cairo::FONT_WEIGHT_NORMAL)
        @context.set_source_rgb(255,255,255)
        @text_array = text_array
        @internal_x_offset = 8
        @internal_y_offset = 4
        @area_size = calc_cell_area()
    end
    def download_image(url, output_path)
        if !FileTest.exist?(output_path) then
            URI.open(url) do |image|
                if !Dir.exist?(File.dirname(output_path)) then
                    Dir.mkdir(File.dirname(output_path))
                end
                File.open(output_path, 'wb') do |file|
                    file.write(image.read)
                end
            end
        end
    end
    def calc_cell_area()
        text_area_width = 0
        text_area_height = 0
        @text_array.each do |text|
            extents = @context.text_extents(text)
            text_area_height = text_area_height + extents.height + @internal_y_offset
            if text_area_width < extents.width then
                text_area_width = extents.width
            end
        end
        return {x: @image.width + @internal_x_offset + text_area_width, y: (@image.height > text_area_height ? @image.height : text_area_height)} 
    end
    def render_cell_area(base_context, pos)
        base_context.set_source(@image, pos[:x], pos[:y])
        base_context.paint
        base_context.set_font_size(16)
        base_context.select_font_face("IPAPGothic",
                    Cairo::FONT_SLANT_NORMAL,
                    Cairo::FONT_WEIGHT_NORMAL)
        base_context.set_source_rgb(255,255,255)
        x_offset = pos[:x] + @image.width + @internal_x_offset
        y_offset = pos[:y]
        @text_array.each do |text|
            base_context.move_to(x_offset, y_offset + base_context.text_extents(text).height)
            base_context.show_text(text)
            y_offset = y_offset + base_context.text_extents(text).height + @internal_y_offset
        end
    end
end
