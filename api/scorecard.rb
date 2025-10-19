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

  def generate(output_path)
    x_offset = 10
    y_offset = 10

    # calc image size
    player_area_size = @player_info.calc_cell_area
    width = x_offset + player_area_size[:x] + x_offset
    height = y_offset + player_area_size[:y] + y_offset
    character_area_total_width = 0
    @list_character.each do |this_character_info|
      character_area_total_height = 0
      this_character_area_max_width = 0
      this_character_info.each do |this_info|
        area_size = this_info.calc_cell_area
        character_area_total_height += area_size[:y] + y_offset
        if this_character_area_max_width < area_size[:x] + x_offset
          this_character_area_max_width = area_size[:x] + x_offset
        end
      end
      if height < y_offset + player_area_size[:y] + y_offset + character_area_total_height
        height = y_offset + player_area_size[:y] + y_offset + character_area_total_height
      end
      character_area_total_width += this_character_area_max_width
    end
    width = x_offset + character_area_total_width if width < x_offset + character_area_total_width

    # render cells
    offset = { x: x_offset, y: y_offset }
    surface = Cairo::ImageSurface.new(width, height)
    context = Cairo::Context.new(surface)

    @player_info.render_cell_area(context, offset)
    area_size = @player_info.calc_cell_area
    offset[:y] += area_size[:y] + y_offset
    @list_character.each do |this_character_info|
      next_offset_x = 0
      next_offset_y = 0
      this_character_info.each do |this_info|
        area_size = this_info.calc_cell_area
        this_offset = { x: offset[:x], y: offset[:y] + next_offset_y }
        this_info.render_cell_area(context, this_offset)
        next_offset_x = next_offset_x < area_size[:x] ? area_size[:x] : next_offset_x
        next_offset_y += area_size[:y] + y_offset
      end
      offset[:x] += next_offset_x + x_offset
    end

    surface.write_to_png(output_path)
  end
end
