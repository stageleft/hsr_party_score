# frozen_string_literal: true

require 'open-uri'
require 'cairo'
require 'json'
require_relative 'scorecard'

# PartyCard
# Generate data for a scorecard class
class PartyCard < ScoreCard
  def initialize(input_json)
    super
    param = JSON.parse(input_json)

    # store player info
    player_id = "ID: #{param['player']['uid']}"
    player_name = "Name: #{param['player']['nickname']}"
    init_player_info({ image: param['player']['avatar']['icon'],
                       text: [player_id, player_name] })

    # store character info
    param['characters'].each do |character|
      info_character(character)
    end
  end

  # all info of single character
  def info_character(character)
    this_character_info = [params_character(character)]
    # skip: rank_icons (with chara_rank)
    # skip: path（運命）, element（属性）
    # skip: skills（スキル）
    # skip: skill_trees（軌跡）
    this_character_info.concat(params_light_cone(character['light_cone']))
    this_character_info.concat(params_relics(character['relics']))
    this_character_info.concat(params_relic_set(character['relic_sets']))
    push_unit_info(this_character_info)
  end

  # basic character info
  def params_character(character)
    string_array = [
      "名前　: #{character['name']}",
      "レベル: #{character['level']}",
      "星魂　:E#{character['rank']}"
    ]
    string_array.concat(string_character_spd(character['statistics'],
                                             character['attributes'],
                                             character['additions']))
    string_array.concat(strings_character_prop(character['properties']))
    { image: character['icon'], text: string_array }
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
  def params_light_cone(light_cone)
    string_array = ["#{light_cone['name']} Lv:#{light_cone['level']} 重畳:#{light_cone['rank']}"]
    # skip: light_cone["attributes"] -> 基礎HP/基礎攻撃力/基礎防御力のみのため速度は含まない
    light_cone['properties'].each do |property|
      next unless property['field'] == 'spd'

      string_array.push("#{property['name']}：#{property['percent'] == true ? property['display'] : property['value']}")
    end
    string_array.length > 1 ? [{ image: light_cone['icon'], text: string_array }] : []
  end

  # relics（遺物、オーナメント）
  def string_relics_main(main_affix)
    ["メイン　#{main_affix['name']}：#{main_affix['percent'] == true ? main_affix['display'] : main_affix['value']}"]
  end

  def string_relics_sub(sub_affix)
    sub_affix.map do |sub|
      "　サブ　#{sub['name']}：#{sub['percent'] == true ? sub['display'] : sub['value']}"
    end
  end

  def params_relics(relics)
    relics_cells = []
    relics.each do |relic|
      string_array = ["#{relic['name']} Lv:#{relic['level']}"]
      string_array.concat(string_relics_main(relic['main_affix']))
      string_array.concat(string_relics_sub(relic['sub_affix']))
      relics_cells.push({ image: relic['icon'], text: string_array })
    end
    relics_cells
  end

  # relic_sets（遺物セット効果、オーナメント含む）
  def params_relic_set(relic_sets)
    relic_sets_cells = []
    relic_sets.each do |effect|
      text = ["#{effect['name']}（#{effect['num']}セット）"]
      effect['properties'].each do |prop|
        text.push("　#{prop['name']}#{prop['percent'] == true ? prop['display'] : prop['value']}")
        relic_sets_cells.push({ image: effect['icon'], text: text })
      end
    end
    relic_sets_cells
  end
end
