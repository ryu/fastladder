class Settings < SettingsCabinet::Base
  using SettingsCabinet::DSL

  source "#{Rails.root.join('config/application.yml')}"
  namespace Rails.env
end
