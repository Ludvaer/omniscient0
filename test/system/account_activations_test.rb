require "application_system_test_case"

class AccountActivationsTest < ApplicationSystemTestCase
  setup do
    @account_activation = account_activations(:one)
  end

  test "visiting the index" do
    visit account_activations_url
    assert_selector "h1", text: "Account activations"
  end

  test "should create account activation" do
    visit account_activations_url
    click_on "New account activation"

    fill_in "Email", with: @account_activation.email
    fill_in "Token", with: @account_activation.token
    fill_in "User", with: @account_activation.user_id
    click_on "Create Account activation"

    assert_text "Account activation was successfully created"
    click_on "Back"
  end

  test "should update Account activation" do
    visit account_activation_url(@account_activation)
    click_on "Edit this account activation", match: :first

    fill_in "Email", with: @account_activation.email
    fill_in "Token", with: @account_activation.token
    fill_in "User", with: @account_activation.user_id
    click_on "Update Account activation"

    assert_text "Account activation was successfully updated"
    click_on "Back"
  end

  test "should destroy Account activation" do
    visit account_activation_url(@account_activation)
    click_on "Destroy this account activation", match: :first

    assert_text "Account activation was successfully destroyed"
  end
end
