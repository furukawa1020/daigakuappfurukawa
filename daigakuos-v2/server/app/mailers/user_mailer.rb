class UserMailer < ApplicationMailer
  default from: 'notifications@daigakuos.com'

  def weekly_report(user)
    @user = user
    @total_time = (user.sessions.where("started_at >= ?", 1.week.ago).sum(:duration) / 60.0).round(1)
    
    # In development, emails are written to the server log. 
    # In production, this uses SendGrid or SES.
    mail(to: "#{user.device_id}@users.daigakuos.com", subject: 'Your DaigakuOS Weekly Digest')
  end
end
