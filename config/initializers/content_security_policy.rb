# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self
    policy.img_src     :self, :data, :https  # RSS feed images from external sources
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
    policy.frame_ancestors :self
    policy.connect_src :self
  end

  # Report violations without enforcing the policy.
  config.content_security_policy_report_only = true

  # Nonce generation disabled in Phase 1 (report-only mode).
  # TODO: Enable in Phase 2 after inline script externalization.
  # config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(32) }
  # config.content_security_policy_nonce_directives = %w[script-src style-src]
end
