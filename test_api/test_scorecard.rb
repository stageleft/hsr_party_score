require_relative '../api/scorecard'

input_json = File.read('../development/test.json')

scorecard = ScoreCard.new(input_json)
output_path = scorecard.generate('output_scorecard.png')
