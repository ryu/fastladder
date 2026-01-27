class Settings < SettingsCabinet::Base
  using SettingsCabinet::DSL

  source Rails.root.join('config/application.yml').to_s
  namespace Rails.env
end
