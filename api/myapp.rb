# frozen_string_literal: true

require 'sinatra'
require_relative 'score_from_mihomo'
require_relative 'partycard'

get '/' do
    send_file './public/index.html'
end

get '/generate' do
    unless params[:uid] =~ /^\d{1,16}$/
        return "Invalid UID. Please provide a valid digit UID."
    end

    uid = params[:uid] || '827841944'
    lang = params[:lang] || 'jp'
    puts "Getting Status from MiHoMo API for UID: #{uid} with language: #{lang}..."
    partycard = PartyCard.new(ScoreFromMiHoMo.new(uid, lang).fetch_data)
    puts "Generating party card image started.."
    partycard.generate('output_scorecard.png')
    puts "Generating party card image finished."
    send_file 'output_scorecard.png', type: :png, disposition: 'inline'
end
