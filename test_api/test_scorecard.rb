# frozen_string_literal: true

require_relative '../api/scorecard'
uid = '827841944'
unless File.exist?("./#{uid}.json")
  puts "Please run test_access.rb first to fetch data for UID #{uid}."
  exit
end
input_json = File.read("./#{uid}.json")

scorecard = ScoreCard.new(input_json)
scorecard.generate('output_scorecard.png')
