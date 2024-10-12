require "test_helper"

class PseudoStaticControllerTest < ActionDispatch::IntegrationTest
  test "should get welcome" do
    get pseudo_root_url(locale:'en')
    assert_response :success
  end
end
