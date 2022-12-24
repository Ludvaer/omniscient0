class UserMailer < ActionMailer::Base
  default from: "MikhailUtochkin@yandex.ru"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.account_activation.subject
  #
  def account_activation(account_activation)
    @account_activation = account_activation
    mail to: account_activation.email, subject: t("Email confirmation")
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def password_reset(user)
    @user = user
    @password_reset = user.password_reset
    mail to: user.email, subject: t("Password reset")
  end
end
