# frozen_string_literal: true

# ScoreCardAnyCell
# A cell that can contain an image and multi-line text.
# [       ] multi-line text
# [1 image] multi-line text
# [       ] multi-line text
class ScoreCardAnyCell
  def initialize(image_path: '', text_array: [''])
    # setup image
    @domain = 'https://raw.githubusercontent.com/Mar-7th/StarRailRes/refs/heads/master/'
    url = "#{@domain}#{image_path}"
    download_image(url, image_path)
    @image = Cairo::ImageSurface.from_png(image_path)
    # setup text context
    @context = Cairo::Context.new(@image)
    font_setup(@context)
    @text_array = text_array
    @internal_x_offset = 8
    @internal_y_offset = 4
  end

  def font_setup(context)
    context.set_font_size(16)
    context.select_font_face('IPAPGothic',
                             Cairo::FONT_SLANT_NORMAL,
                             Cairo::FONT_WEIGHT_NORMAL)
    context.set_source_rgb(255, 255, 255)
  end

  def download_image(url, output_path)
    return if FileTest.exist?(output_path)

    URI.parse(url).open do |image|
      FileUtils.mkdir_p(File.dirname(output_path))
      File.binwrite(output_path, image.read)
    end
  end

  def calc_cell_width
    text_area_width = [0]
    @text_array.each do |text|
      extents = @context.text_extents(text)
      text_area_width.push(extents.width)
    end
    [@image.width, @internal_x_offset, text_area_width.max].sum
  end

  def calc_cell_height
    text_area_height = [0]
    @text_array.each do |text|
      extents = @context.text_extents(text)
      text_area_height.push(extents.height)
      text_area_height.push(@internal_y_offset)
    end
    [@image.height, text_area_height.sum].max
  end

  def calc_cell_area
    { x: calc_cell_width, y: calc_cell_height }
  end

  def render_cell_text(base_context, x_offset, y_offset)
    font_setup(base_context)
    @text_array.each do |text|
      base_context.move_to(x_offset, y_offset + base_context.text_extents(text).height)
      base_context.show_text(text)
      y_offset = y_offset + base_context.text_extents(text).height + @internal_y_offset
    end
  end

  def render_cell_area(base_context, pos)
    base_context.set_source(@image, pos[:x], pos[:y])
    base_context.paint
    render_cell_text(base_context, pos[:x] + @image.width + @internal_x_offset, pos[:y])
  end
end
