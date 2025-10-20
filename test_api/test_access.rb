# frozen_string_literal: true

require_relative '../api/score_from_mihomo'

uid = '827841944'
score_object = ScoreFromMiHoMo.new(uid)

score_json = score_object.fetch_data
File.open("#{uid}.json", 'w') do |file|
  file.write(score_json)
end
