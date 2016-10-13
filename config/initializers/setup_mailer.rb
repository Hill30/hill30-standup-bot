Rails.application.config.action_mailer.default_url_options = { host: Settings.app.host }
Rails.application.config.action_mailer.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
    address:              Settings.mailer.address,
    domain:               Settings.mailer.domain,
    port:                 587,
    user_name:            Settings.mailer.user_name,
    password:             Settings.mailer.password,
    authentication:       Settings.mailer.authentication,
    enable_starttls_auto: Settings.mailer.enable_starttls_auto,
    openssl_verify_mode:  Settings.mailer.openssl_verify_mode
}