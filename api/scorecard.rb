# frozen_string_literal: true

require 'open-uri'
require 'cairo'
require 'json'
require_relative 'scorecard_anycell'

# ScoreCard
# Generate a scorecard image from player and character data.
class ScoreCard
  def initialize(input_json = '{}')
    param = JSON.parse(input_json)

    # store player info
    player_id = "ID: #{param['player']['uid']}"
    player_name = "Name: #{param['player']['nickname']}"
    @player_info = ScoreCardAnyCell.new(image_path: param['player']['avatar']['icon'].to_s,
                                        text_array: [player_id,
                                                     player_name])

    # store character info
    @list_character = []
    param['characters'].each do |character|
      @list_character.push(info_character(character))
    end
  end

  # all info of single character
  def info_character(character)
    this_character_info = []
    this_character_info.concat(cells_character(character))
    # skip: rank_icons (with chara_rank)
    # skip: path（運命）, element（属性）
    # skip: skills（スキル）
    # skip: skill_trees（軌跡）
    this_character_info.concat(cells_light_cone(character['light_cone']))
    this_character_info.concat(cells_relics(character['relics']))
    this_character_info.concat(cells_relic_set(character['relic_sets']))
    this_character_info
  end

  # basic character info
  def cells_character(character)
    string_array = [
      "名前　: #{character['name']}",
      "レベル: #{character['level']}",
      "星魂　:E#{character['rank']}"
    ]
    string_array.concat(string_character_spd(character['statistics'],
                                             character['attributes'],
                                             character['additions']))
    string_array.concat(strings_character_prop(character['properties']))

    [ScoreCardAnyCell.new(image_path: character['icon'], text_array: string_array)]
  end

  # statistics, attributes, additions（ステータス）
  def string_character_spd(statistics, attributes, additions)
    string_array = []
    [statistics, attributes, additions].flatten.each do |element|
      next unless element['field'] == 'spd'

      string_array.push("#{element['name']}　　　　　　: #{element['value']}")
    end
    string_array
  end

  # properties（ステータス）
  def strings_character_prop(properties)
    string_array = []
    properties.each do |property|
      next unless property['field'] == 'spd'

      if property['percent'] == true
        string_array.push("速度補正％＠個別: #{property['display']}")
      else
        string_array.push("速度補正値＠個別: #{property['value']}")
      end
    end
    string_array
  end

  # light_cone（光円錐）
  def cells_light_cone(light_cone)
    string_array = ["#{light_cone['name']} Lv:#{light_cone['level']} 重畳:#{light_cone['rank']}"]
    # skip: light_cone["attributes"] -> 基礎HP/基礎攻撃力/基礎防御力のみのため速度は含まない
    light_cone['properties'].each do |property|
      next unless property['field'] == 'spd'

      string_array.push("#{property['name']}：#{property['percent'] == true ? property['display'] : property['value']}")
    end
    string_array.length > 1 ? [ScoreCardAnyCell.new(image_path: light_cone['icon'], text_array: string_array)] : []
  end

  # relics（遺物、オーナメント）
  def string_relics_main(main_affix)
    if main_affix['field'] == 'spd'
      ["　メイン #{main_affix['name']}：#{main_affix['percent'] == true ? main_affix['display'] : main_affix['value']}"]
    else
      []
    end
  end

  def string_relics_sub(sub_affix)
    string_array = []
    sub_affix.each do |sub|
      next unless sub['field'] == 'spd'

      string_array.push("　サブ　 #{sub['name']}：#{sub['percent'] == true ? sub['display'] : sub['value']}")
    end
    string_array
  end

  def cells_relics(relics)
    relics_cells = []
    relics.each do |relic|
      string_array = ["#{relic['name']}（#{relic['set_name']}） Lv:#{relic['level']}"]
      string_array.concat(string_relics_main(relic['main_affix']))
      string_array.concat(string_relics_sub(relic['sub_affix']))
      relics_cells.push(ScoreCardAnyCell.new(image_path: relic['icon'], text_array: string_array))
    end
    relics_cells
  end

  # relic_sets（遺物セット効果、オーナメント含む）
  def cells_relic_set(relic_sets)
    relic_sets_cells = []
    relic_sets.each do |effect|
      effect['properties'].each do |prop|
        next unless prop['field'] == 'spd'

        text = "#{effect['name']}（#{effect['num']}セット）：" \
               "#{prop['name']}#{prop['percent'] == true ? prop['display'] : prop['value']}"
        relic_sets_cells.push(ScoreCardAnyCell.new(image_path: effect['icon'], text_array: [text]))
      end
    end
    relic_sets_cells
  end

  def char_area_width(this_character_info)
    area_width = [0]
    this_character_info.each do |this_info|
      area_width.push(this_info.calc_cell_area[:x])
    end
    area_width.max
  end

  def char_area_all_width(x_offset)
    area_width = [x_offset]
    @list_character.each do |this_character_info|
      area_width.push(char_area_width(this_character_info))
      area_width.push(x_offset)
    end
    area_width.sum
  end

  def char_area_height(this_character_info, y_offset)
    area_height = [0]
    this_character_info.each do |this_info|
      area_height.push(this_info.calc_cell_area[:y])
      area_height.push(y_offset)
    end
    area_height.sum
  end

  def char_area_all_height(y_offset)
    area_height = [0]
    @list_character.each do |this_character_info|
      area_height.push(char_area_height(this_character_info, y_offset))
    end
    area_height.max
  end

  def image_size(x_offset, y_offset)
    player_area_size = @player_info.calc_cell_area
    player_area_width = x_offset + player_area_size[:x] + x_offset
    player_area_height = y_offset + player_area_size[:y] + y_offset
    { width: [player_area_width, char_area_all_width(x_offset)].max,
      height: player_area_height + char_area_all_height(y_offset) }
  end

  def render_character_area(context, offset, y_padding, this_character_info)
    x_pos = offset[:x]
    y_pos = offset[:y]
    this_character_info.each do |this_info|
      area_size = this_info.calc_cell_area
      this_offset = { x: x_pos, y: y_pos }
      this_info.render_cell_area(context, this_offset)
      y_pos += area_size[:y] + y_padding
    end
  end

  def render_card(context, offset)
    @player_info.render_cell_area(context, offset)
    area_size = @player_info.calc_cell_area

    char_area_offset = { x: offset[:x], y: offset[:y] + (area_size[:y] + offset[:y]) }
    @list_character.each do |this_character_info|
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
