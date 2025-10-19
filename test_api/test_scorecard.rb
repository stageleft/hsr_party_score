require_relative '../api/scorecard'

input_json = File.read('../development/test.json')

scorecard = ScoreCard.new
output_path = scorecard.generate(input_json, 'output_scorecard.png')
