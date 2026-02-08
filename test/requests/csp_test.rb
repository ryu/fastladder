require "test_helper"

class CspTest < ActionDispatch::IntegrationTest
  test "CSP report-only header is present on HTML responses" do
    get "/reader"
    csp = response.headers["Content-Security-Policy-Report-Only"]
    assert csp.present?, "CSP report-only header should be present"
    assert_match(/default-src 'self'/, csp)
    assert_match(/script-src 'self'/, csp)
    assert_match(/style-src 'self'/, csp)
    assert_match(/object-src 'none'/, csp)
    assert_match(/img-src 'self' data: https:/, csp)
  end

  test "CSP does not use enforce mode" do
    get "/reader"
    assert_nil response.headers["Content-Security-Policy"],
      "CSP should be report-only, not enforced"
  end
end
