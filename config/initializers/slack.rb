Slack.configure do |config|
  config.token = 'xoxb-75680063014-q1JPbigyGoRHyASQjP6vhDiR'
  fail 'Missing ENV[SLACK_API_TOKEN]!' unless config.token

  Slack::RealTime.configure do |config|
    config.concurrency = Slack::RealTime::Concurrency::Eventmachine
  end

end
