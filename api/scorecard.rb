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

    # store charactor info
    @character_info = []
    param['characters'].each do |charactor|
      this_character_info = []
      # basic character info, statistics, attributes, additions, properties （ステータス）
      string_array = []
      string_array.push("名前　: #{charactor['name']}")
      string_array.push("レベル: #{charactor['level']}")
      string_array.push("星魂　:E#{charactor['rank']}")
      statistics = charactor['statistics']
      statistics.each do |statistic|
        string_array.push("速度値　　　　　: #{statistic['value']}") if statistic['field'] == 'spd'
      end
      attributes = charactor['attributes']
      attributes.each do |attribute|
        string_array.push("基礎速度　　　　: #{attribute['value']}") if attribute['field'] == 'spd'
      end
      additions = charactor['additions']
      additions.each do |addition|
        string_array.push("速度補正値＠全体： #{addition['value']}") if addition['field'] == 'spd'
      end
      properties = charactor['properties']
      properties.each do |property|
        if property['field'] == 'spd'
          if property['percent'] == true
            string_array.push("速度補正％＠個別: #{property['display']}")
          else
            string_array.push("速度補正値＠個別: #{property['value']}")
          end
        end
      end
      this_character_info.push(ScoreCardAnyCell.new(image_path: charactor['icon'].to_s, text_array: string_array))
      # skip: rank_icons (with chara_rank)
      # skip: path（運命）, element（属性）
      # skip: skills（スキル）
      # skip: skill_trees（軌跡）

      # light_cone（光円錐）
      light_cone = charactor['light_cone']
      string_array = []
      string_array.push("#{light_cone['name']} Lv:#{light_cone['level']} 重畳:#{light_cone['rank']}")
      # skip: light_cone["attributes"] -> 基礎HP/基礎攻撃力/基礎防御力のみのため速度は含まない
      light_cone['properties'].each do |property|
        if property['field'] == 'spd'
          if property['percent'] == true
            stringArray.push("#{property['name']}：#{property['display']}")
          else
            stringArray.push("#{property['name']}：#{property['value']}")
          end
        end
      end
      if string_array.length > 1
        this_character_info.push(ScoreCardAnyCell.new(image_path: light_cone['icon'].to_s,
                                                      text_array: string_array))
      end

      # relics（遺物、オーナメント）
      relics = charactor['relics']
      relics.each do |relic|
        string_array = ["#{relic['name']}（#{relic['set_name']}） Lv:#{relic['level']}"]
        relic_icon_path = relic['icon'].to_s
        main_affix = relic['main_affix']
        if main_affix['field'] == 'spd'
          if relic['main_affix']['percent'] == true
            string_array.push("　メイン #{relic['main_affix']['name']}：#{relic['main_affix']['display']}")
          else
            string_array.push("　メイン #{relic['main_affix']['name']}：#{relic['main_affix']['value']}")
          end
        end
        relic['sub_affix'].each do |sub_affix|
          if sub_affix['field'] == 'spd'
            if sub_affix['percent'] == true
              string_array.push("　サブ　 #{sub_affix['name']}：#{sub_affix['display']}")
            else
              string_array.push("　サブ　 #{sub_affix['name']}：#{sub_affix['value']}")
            end
          end
        end
        this_character_info.push(ScoreCardAnyCell.new(image_path: relic_icon_path, text_array: string_array))
      end

      # relic_sets（遺物セット効果、オーナメント含む）
      relic_sets = charactor['relic_sets']
      string_array = []
      relic_sets.each do |effect|
        effect['properties'].each do |property|
          if property['field'] == 'spd'
            if property['percent'] == true
              this_character_info.push(ScoreCardAnyCell.new(image_path: effect['icon'].to_s,
                                                            text_array: ["#{effect['name']}（#{effect['num']}セット）：#{property['name']}#{property['display']}"]))
            else
              this_character_info.push(ScoreCardAnyCell.new(image_path: effect['icon'].to_s,
                                                            text_array: ["#{effect['name']}（#{effect['num']}セット）：#{property['name']}#{property['value']}"]))
            end
          end
        end
      end

      @character_info.push(this_character_info)
    end
  end

  def generate(output_path)
    x_offset = 10
    y_offset = 10

    # calc image size
    player_area_size = @player_info.calc_cell_area
    width = x_offset + player_area_size[:x] + x_offset
    height = y_offset + player_area_size[:y] + y_offset
    character_area_total_width = 0
    @character_info.each do |this_character_info|
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
    @character_info.each do |this_character_info|
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
