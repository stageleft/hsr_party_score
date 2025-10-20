# frozen_string_literal: true

require 'open-uri'

# ScoreFromMiHoMo
# Fetch scorecard data from MiHoMo API.
class ScoreFromMiHoMo
  def initialize(uid, lang = 'jp')
    @api_url = "https://api.mihomo.me/sr_info_parsed/#{uid}?l=#{lang}"
    @api_header = {
      'User-Agent' => 'https://github.com/stageleft/hsr_party_score'
    }
  end

  def fetch_data
    URI.parse(@api_url).read(@api_header)
  end
end
