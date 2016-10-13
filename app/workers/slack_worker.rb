require 'rufus-scheduler'

class SlackWorker
  include Sidekiq::Worker

  sidekiq_options queue: "slack"

  def perform()
    client = Slack::RealTime::Client.new
    webClient = Slack::Web::Client.new
    scheduler = Rufus::Scheduler.new

    users = {}

    client.on :hello do
      p "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
      scheduler.cron '00 15,16,17,18 * * 1-5' do
        User.where(enabled: true).each do |u|
          unless u.daily_reports.where(created_at: Date.today.midnight..Date.today.end_of_day).exists?
            channel = webClient.users_info(user:"@#{u.email.split("@")[0]}")['user']['id']
            webClient.chat_postMessage(channel: channel, text: "Time to daily report! #{ Slackbot::Workflow::HELP_MESSAGE }", as_user: true)
          end
        end
      end

      scheduler.cron '* * * * *' do
        # TODO: send daily reminder here
        p "ping #{ Time.now }"
      end

      scheduler.cron '00 13 14 15 * * 4-6' do
        email = ['kkataev@hill30.com', 'kivanov@hill30.com', 'ishamatov@hill30.com', 'ikirichenko@hill30.com', 'kdobretsov@hill30.com', 'npakudin@hill30.com', 'ykononov@hill30.com']
        User.where(email: email).each do |u|
          unless u.timesheets.where(created_at: Date.today.at_beginning_of_week..Date.today.end_of_day).exists?
            channel = webClient.users_info(user:"@#{u.email.split("@")[0]}")['user']['id']
            webClient.chat_postMessage(channel: channel, text: "Time to fill your weekly timesheet! Please do it ASAP until Friday evening! Answer on it message. #{ Slackbot::Workflow::TIMESHEET_MESSAGE }", as_user: true)
          end
        end
      end

      #scheduler.cron '00 20 * * 6-6' do
      scheduler.cron '32 19 * * 2-2' do
        p "ping #{ Time.now } nnnn"
        #ReportMailer.report_email().deliver_now      
      end

    end

    client.on :message do |data|

      p data.user + ": " + data.text

      unless users[data.channel]
        users[data.channel] = {
          registered: false,
          ready_to_set_password: false,
          ready_to_select_team: false,
          team: nil,
          started: false,
          current_step: nil,
          report: {}
        }
      end

      context = { client: client, webClient: webClient, data: data, user: users[data.channel] }

      if context[:user][:ready_to_set_password]
        Slackbot::Workflow.doSetPassword context
        next
      end

      if context[:user][:ready_to_select_team]
        Slackbot::Workflow.doSelectTeam context
        next
      end

      if context[:user][:ready_to_send_timesheet]
        Slackbot::Workflow.sendTimesheet context
        next
      end     

      case data.text
        when '-t' then Slackbot::Workflow.doTest context
        when '-h' then Slackbot::Workflow.doHelp context
        when '-r' then Slackbot::Workflow.doRegister context
        when '-s' then Slackbot::Workflow.doStartReport context
        when '-n' then Slackbot::Workflow.doNextReportStatement context
        
        when '-skip' then Slackbot::Workflow.doSkipTimesheet context
        when '-send' then Slackbot::Workflow.doStartTimesheet context

        else Slackbot::Workflow.doDefault context
      end

    end

    client.on :close do |_data|
      p "Client is about to disconnect"
    end

    client.on :closed do |_data|
      p "Client has disconnected successfully!"
    end

    client.start_async
  end
end
