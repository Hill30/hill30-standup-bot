class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,# :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :daily_reports
  has_many :timesheets
  
  scope :without_daily_report, -> {
    includes(:daily_reports)
    .where(users: { enabled: true })
    .where.not.(daily_reports: {created_at: Date.today.midnight..Date.today.end_of_day })
  }

end
