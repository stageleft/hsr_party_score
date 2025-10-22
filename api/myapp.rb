# frozen_string_literal: true

require 'sinatra'
require_relative 'score_from_mihomo'
require_relative 'partycard'

get '/' do
    send_file './public/index.html'
end

get '/generate/:uid' do
    uid = params['type'] || '827841944'
    partycard = PartyCard.new(ScoreFromMiHoMo.new(uid).fetch_data)
    partycard.generate('output_scorecard.png')
    send_file 'output_scorecard.png', type: :png, disposition: 'inline'
end
