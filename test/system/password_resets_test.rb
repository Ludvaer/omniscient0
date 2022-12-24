require "application_system_test_case"

class PasswordResetsTest < ApplicationSystemTestCase
  setup do
    @password_reset = password_resets(:one)
  end

  test "visiting the index" do
    visit password_resets_url
    assert_selector "h1", text: "Password resets"
  end

  test "should create password reset" do
    visit password_resets_url
    click_on "New password reset"

    fill_in "Token", with: @password_reset.token
    fill_in "User", with: @password_reset.user_id
    click_on "Create Password reset"

    assert_text "Password reset was successfully created"
    click_on "Back"
  end

  test "should update Password reset" do
    visit password_reset_url(@password_reset)
    click_on "Edit this password reset", match: :first

    fill_in "Token", with: @password_reset.token
    fill_in "User", with: @password_reset.user_id
    click_on "Update Password reset"

    assert_text "Password reset was successfully updated"
    click_on "Back"
  end

  test "should destroy Password reset" do
    visit password_reset_url(@password_reset)
    click_on "Destroy this password reset", match: :first

    assert_text "Password reset was successfully destroyed"
  end
end
