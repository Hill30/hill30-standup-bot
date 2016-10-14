Slack.configure do |config|
  config.token = ENV["SLACK_API_TOKEN"]
  fail 'Missing ENV[SLACK_API_TOKEN]!' unless config.token

  Slack::RealTime.configure do |config|
    config.concurrency = Slack::RealTime::Concurrency::Eventmachine
  end

end
