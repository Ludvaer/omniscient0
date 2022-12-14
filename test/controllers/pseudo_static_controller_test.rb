require "test_helper"

class PseudoStaticControllerTest < ActionDispatch::IntegrationTest
  test "should get welcome" do
    get pseudo_static_welcome_url
    assert_response :success
  end
end
