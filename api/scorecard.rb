require 'open-uri'
require 'cairo'
require 'json'

class ScoreCard
    def initialize(width: 6300, height: 10+(128+10)+(256+10)*8)
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
                if !Dir.exist?(File.dirname(output_path)) then
                    Dir.mkdir(File.dirname(output_path))
                end
                File.open(output_path, 'wb') do |file|
                    file.write(image.read)
                end
            end
        end
    end
    def write_text_to_cairo_context(context, x, y, textArray)
        textArray.each_with_index do |text, index|
            context.move_to(x, y + ((index + 1) * @pointsize))
            context.set_font_size(@pointsize)
            context.select_font_face("IPAPGothic",
                        Cairo::FONT_SLANT_NORMAL,
                        Cairo::FONT_WEIGHT_NORMAL)
            context.set_source_rgb(255,255,255)
            context.show_text(text)
        end
        return
    end
    def write_image_and_text_to_cairo_context(context, x, y, image, textArray)
        image = Cairo::ImageSurface.from_png(image)
        context.set_source(image, x, y)
        context.paint
        write_text_to_cairo_context(context, x + image.width, y, textArray)
        return image.height
    end
    def generate(input_json = "{}", output_path = "scorecard.png")
        param = JSON.parse(input_json)
        surface = Cairo::ImageSurface.new(@width, @height)
        context = Cairo::Context.new(surface)
        y_offset = 10

        # player info
        player_id = "ID: #{param["player"]["uid"]}"
        player_name = "Name: #{param["player"]["nickname"]}"
        player_icon_path = "#{param["player"]["avatar"]["icon"]}"
        player_icon_url = "#{@domain}#{param["player"]["avatar"]["icon"]}"
        download_image(player_icon_url, player_icon_path)
        y_offset = write_image_and_text_to_cairo_context(context, 0, y_offset, player_icon_path, [player_id, player_name])
        y_offset = y_offset + 10

        # charactor info
        param["characters"].each_with_index do |charactor, index|
            chara_icon_path = "#{charactor["icon"]}"
            chara_icon_url = "#{@domain}#{charactor["icon"]}"
            download_image(chara_icon_url, chara_icon_path)
            chara_name = "Name: #{charactor["name"]}"
            chara_level = "Level: #{charactor["level"]}"
            chara_rank = "Rank: E#{charactor["rank"]}"
            next_y_offset = y_offset + write_image_and_text_to_cairo_context(context, 0, y_offset, chara_icon_path, [chara_name, chara_level, chara_rank])
            # statistics, attributes, additions, properties （ステータス）
            statistics = charactor["statistics"]
            attributes = charactor["attributes"]
            additions = charactor["additions"]
            properties = charactor["properties"]
            stringArray = []
            statistics.each do |statistic|
                stat_name = statistic["name"]
                stat_value = statistic["value"]
                stat_value_disp = statistic["display"]
                stat_percent = statistic["percent"]
                if (stat_percent == true) then
                    stringArray.push("#{stat_name}: #{stat_value_disp}")
                else
                    stringArray.push("#{stat_name}: #{stat_value}")
                end
            end
            write_text_to_cairo_context(context, 450, y_offset, stringArray)
            stringArray = []
            attributes.each do |attribute|
                stat_name = attribute["name"]
                stat_value = attribute["value"]
                stat_value_disp = attribute["display"]
                stat_percent = attribute["percent"]
                if (stat_percent == true) then
                    stringArray.push("#{stat_name}: #{stat_value_disp}")
                else
                    stringArray.push("#{stat_name}: #{stat_value}")
                end
            end
            write_text_to_cairo_context(context, 750, y_offset, stringArray)
            stringArray = []
            additions.each do |addition|
                stat_name = addition["name"]
                stat_value = addition["value"]
                stat_value_disp = addition["display"]
                stat_percent = addition["percent"]
                if (stat_percent == true) then
                    stringArray.push("#{stat_name}: #{stat_value_disp}")
                else
                    stringArray.push("#{stat_name}: #{stat_value}")
                end
            end
            write_text_to_cairo_context(context, 1050, y_offset, stringArray)
            stringArray = []
            properties.each do |property|
                stat_name = property["name"]
                stat_value = property["value"]
                stat_value_disp = property["display"]
                stat_percent = property["percent"]
                if (stat_percent == true) then
                    stringArray.push("#{stat_name}: #{stat_value_disp}")
                else
                    stringArray.push("#{stat_name}: #{stat_value}")
                end
            end
            write_text_to_cairo_context(context, 1350, y_offset, stringArray)
            # skip: rank_icons (with chara_rank)
            # skip: path（運命）, element（属性）
            # skills（スキル）
            skills = charactor["skills"]
            stringArray = []
            skills.each_with_index do |skill, skill_index|
                if (skill["type_text"].size > 0) then
                    stringArray.push("#{skill["type_text"]}「#{skill["name"]}」：#{skill["level"]}/#{skill["max_level"]}")
                end
            end
            write_text_to_cairo_context(context, 1650, y_offset, stringArray)
            # skip: skill_trees（軌跡）
            # light_cone（光円錐）
            light_cone = charactor["light_cone"]
            stringArray = ["#{light_cone["name"]} Lv:#{light_cone["level"]} 重畳:#{light_cone["rank"]}"]
            light_cone["attributes"].each do |attribute|
                stringArray.push("#{attribute["name"]}：#{attribute["value"]}")
            end
            light_cone["properties"].each do |property|
                if (property["percent"] == true) then
                    stringArray.push("#{property["name"]}：#{property["display"]}")
                else
                    stringArray.push("#{property["name"]}：#{property["value"]}")
                end
            end
            write_text_to_cairo_context(context, 1950, y_offset, stringArray)
            # relics
            charactor["relics"].each_with_index do |relic, relic_index|
                relic_icon_path = "#{relic["icon"]}"
                relic_icon_url = "#{@domain}#{relic["icon"]}"
                download_image(relic_icon_url, relic_icon_path)
                stringArray = ["#{relic["name"]}（#{relic["set_name"]}） Lv:#{relic["level"]}"]
                if (relic["main_affix"]["percent"] == true) then
                    stringArray.push("メイン #{relic["main_affix"]["name"]}：#{relic["main_affix"]["display"]}")
                else
                    stringArray.push("メイン #{relic["main_affix"]["name"]}：#{relic["main_affix"]["value"]}")
                end
                relic["sub_affix"].each do |affix|
                    if (relic["main_affix"]["percent"] == true) then
                        stringArray.push("　サブ #{affix["name"]}：#{affix["display"]}")
                    else
                        stringArray.push("　サブ #{affix["name"]}：#{affix["value"]}")
                    end
                end
                write_image_and_text_to_cairo_context(context, 2300 + 600 * relic_index, y_offset, relic_icon_path, stringArray)
            end
            # TODO: relic_sets
            stringArray = ["＜セット効果＞"]
            charactor["relic_sets"].each do |effect|
                effect["properties"].each do |property|
                    if (property["percent"] == true) then
                        stringArray.push("・#{effect["name"]}（#{effect["num"]}セット）：#{property["name"]}#{property["display"]}")
                    else
                        stringArray.push("・#{effect["name"]}（#{effect["num"]}セット）：#{property["name"]}#{property["value"]}")
                    end
                end
            end
            write_text_to_cairo_context(context, 5900, y_offset, stringArray)
            # update y_offset and goto next charactor
            y_offset = next_y_offset + 10
        end

        surface.write_to_png(output_path)
    end
end