class Slackbot::Workflow

  STEP_CHAT_MESSAGE = [
    'What has been done? (-n to next statement)',
    'What are you working on? (-n to next statement)',
    'Any problems? (-n to finish)'
  ]
  STEP_REPORT_MESSAGE = [
    'Completed',
    'Working on',
    'Any problems?'
  ]
  HELP_MESSAGE = 'hill30-standup-bot help:
  -h help
  -r register
  -s start daily report
  -n next report statement'

  TIMESHEET_MESSAGE = 'Please, type -send to write timesheet. (Or -skip if you don\'t work)'



  def self.getRegisteredUser(context)
    if context[:user][:registered]
      return context[:user]
    end
    if not (Slackbot::Auth.getRegisteredUser(context)).blank?
      context[:user][:registered] = true
      return context[:user]
    end
    Slackbot::Message.send context, "Permission denied. Registration is needed. Type -r to start registration."
    return false
  end


  def self.doTest(context)
    Slackbot::Message.send context, "Test passed."
  end


  def self.doHelp(context)
    Slackbot::Message.send context, HELP_MESSAGE
  end


  def self.doRegister(context)
    if Slackbot::Auth.doRegisterStart context
      context[:user][:ready_to_set_password] = true
      Slackbot::Message.send context, "Please enter your password."
    end
  end


  def self.doStartReport(context)
    return unless user = self.getRegisteredUser(context)
    user[:started] = true
    Slackbot::Message.send context, "Hi <@#{context[:data].user}>! Lets start the standup!"
    if Slackbot::Teams.outputList context
      user[:ready_to_select_team] = true
    end
  end


  def self.doNextReportStatement(context)
    return unless user = self.getRegisteredUser(context)
    if user[:started] # TODO: Check that daily report already exist
      if user[:current_step] < 2
        user[:current_step] = user[:current_step] + 1
        Slackbot::Message.send context, STEP_CHAT_MESSAGE[user[:current_step]]
      else # the last step, save the report
        if result = Slackbot::Report.save(context)
          p result
          user[:started] = false
          user[:current_step] = nil
          user[:report] = {}
        end
      end
    end
  end


  def self.doSetPassword(context)
    user = context[:user]
    if Slackbot::Auth.doRegister context
      user[:ready_to_set_password] = false
    end
  end


  def self.doSelectTeam(context)
    return unless user = self.getRegisteredUser(context)
     if team = Slackbot::Teams.select(context)
       user[:team] = team
       user[:current_step] = 0
       Slackbot::Message.send context, STEP_CHAT_MESSAGE[0]
     end
     user[:ready_to_select_team] = false
  end


  def self.doDefault(context)
    user = context[:user]
    if user[:started] && (step = user[:current_step])
      return unless self.getRegisteredUser(context)
      user[:report][step] = [] if user[:report][step].nil?
      user[:report][step] << context[:data].text
    end
  end

 
  def self.doSkipTimesheet(context)
    return unless self.getRegisteredUser(context)
    userData = context[:webClient].users_info(user: context[:data].user)
    email = userData['user']['profile']['email']
    user =  User.find_by(email: email)

    if result = user.timesheets.create!({ description: nil, send_timesheet_remider: false})
      Slackbot::Message.send(context, "You skip report successfully.")
    else
      Slackbot::Message.send(context, "Can't save a user to DB.")
    end 
  end

  def self.doStartTimesheet(context)
    user = context[:user]
    Slackbot::Message.send(context, "Write and send timesheet.")
    user[:ready_to_send_timesheet] = true
  end

  def self.sendTimesheet(context)
    return unless self.getRegisteredUser(context)
    userData = context[:webClient].users_info(user: context[:data].user)
    email = userData['user']['profile']['email']
    user =  User.find_by(email: email)

    if result = user.timesheets.create!({ description: context[:data].text, send_timesheet_remider: true})
      Slackbot::Message.send(context, "You send timesheet successfully.")
    else
      Slackbot::Message.send(context, "Can't save a timesheet to DB.")
    end

    user = context[:user]    
    user[:ready_to_send_timesheet] = false

  end

end
