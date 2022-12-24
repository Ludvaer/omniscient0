require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @password_reset = password_resets(:one)
  end

  test "should get index" do
    get password_resets_url
    assert_response :success
  end

  test "should get new" do
    get new_password_reset_url
    assert_response :success
  end

  test "should create password_reset" do
    assert_difference("PasswordReset.count") do
      post password_resets_url, params: { password_reset: { token: @password_reset.token, user_id: @password_reset.user_id } }
    end

    assert_redirected_to password_reset_url(PasswordReset.last)
  end

  test "should show password_reset" do
    get password_reset_url(@password_reset)
    assert_response :success
  end

  test "should get edit" do
    get edit_password_reset_url(@password_reset)
    assert_response :success
  end

  test "should update password_reset" do
    patch password_reset_url(@password_reset), params: { password_reset: { token: @password_reset.token, user_id: @password_reset.user_id } }
    assert_redirected_to password_reset_url(@password_reset)
  end

  test "should destroy password_reset" do
    assert_difference("PasswordReset.count", -1) do
      delete password_reset_url(@password_reset)
    end

    assert_redirected_to password_resets_url
  end
end
