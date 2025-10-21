# frozen_string_literal: true

require 'open-uri'
require 'cairo'
require 'json'
require_relative 'scorecard_anycell'

# ScoreCard
# Generate a scorecard image from player and character data.
class ScoreCard
  def initialize(input = nil)
    @player_info = nil
    @unit_info = []
    return unless input.nil?

    throw NotImplementedError, 'This is an abstract class. Please use a subclass.'
  end

  def init_player_info(cell_param)
    @player_info = ScoreCardAnyCell.new(cell_param[:image],
                                        cell_param[:text])
  end

  def push_unit_info(cell_array_param)
    character = cell_array_param.map do |character_param|
      ScoreCardAnyCell.new(character_param[:image],
                           character_param[:text])
    end
    @unit_info.push(character)
  end

  def char_area_width(this_character_info)
    area_width = [0]
    this_character_info.each do |this_info|
      area_width.push(this_info.calc_area[:x])
    end
    area_width.max
  end

  def char_area_all_width(x_offset)
    area_width = [x_offset]
    @unit_info.each do |this_character_info|
      area_width.push(char_area_width(this_character_info))
      area_width.push(x_offset)
    end
    area_width.sum
  end

  def char_area_height(this_character_info, y_offset)
    area_height = [0]
    this_character_info.each do |this_info|
      area_height.push(this_info.calc_area[:y])
      area_height.push(y_offset)
    end
    area_height.sum
  end

  def char_area_all_height(y_offset)
    area_height = [0]
    @unit_info.each do |this_character_info|
      area_height.push(char_area_height(this_character_info, y_offset))
    end
    area_height.max
  end

  def image_size(x_offset, y_offset)
    player_area_size = @player_info.calc_area
    player_area_width = x_offset + player_area_size[:x] + x_offset
    player_area_height = y_offset + player_area_size[:y] + y_offset
    { width: [player_area_width, char_area_all_width(x_offset)].max,
      height: player_area_height + char_area_all_height(y_offset) }
  end

  def render_character_area(context, offset, y_padding, this_character_info)
    x_pos = offset[:x]
    y_pos = offset[:y]
    this_character_info.each do |this_info|
      area_size = this_info.calc_area
      this_offset = { x: x_pos, y: y_pos }
      this_info.render_area(context, this_offset)
      y_pos += area_size[:y] + y_padding
    end
  end

  def render_card(context, offset)
    @player_info.render_area(context, offset)
    area_size = @player_info.calc_area

    char_area_offset = { x: offset[:x], y: offset[:y] + (area_size[:y] + offset[:y]) }
    @unit_info.each do |this_character_info|
      render_character_area(context, char_area_offset, offset[:y], this_character_info)
      char_area_offset[:x] += char_area_width(this_character_info) + offset[:x]
    end
  end

  def generate(output_path)
    x_offset = 10
    y_offset = 10

    canvas = image_size(x_offset, y_offset)

    offset = { x: x_offset, y: y_offset }
    surface = Cairo::ImageSurface.new(canvas[:width], canvas[:height])
    context = Cairo::Context.new(surface)
    render_card(context, offset)

    surface.write_to_png(output_path)
  end
end
