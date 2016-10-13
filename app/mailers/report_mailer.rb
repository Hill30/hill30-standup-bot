class ReportMailer < ApplicationMailer
  default from: Settings.mailer.from
  layout 'mailer'
  def report_email()
    user_emails = 'kirilkataev@gmail.com, kkataev@hill30.com'

    @date_start = Date.today-5.days
    @date_end = Date.today+1.days
    @team = Team.first
    @reports = @team.blank? ? nil : DailyReport
                .where(team_id: @team, created_at: @date_start..@date_end, users: { send_timesheet_remider: true } )
                .select("DISTINCT ON(user_id) *")
                .order("user_id, daily_reports.created_at DESC")
                .includes(:user)
    p @reports

    mail(to: user_emails, subject: 'Report')
  end
end
