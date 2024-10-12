# require "test_helper"
#
# class AccountActivationsControllerTest < ActionDispatch::IntegrationTest
#   setup do
#     @user = users(:one)
#     post users_url, params: { user: { activated: @user.activated, downame: @user.downame, email: @user.email, name: @user.name, password_digest: @user.password_digest, token: @user.token } }
#     @account_activation = account_activations(:one)
#   end
#
#   test "should get index" do
#     get account_activations_url
#     assert_response :success
#   end
#
#   test "should get new" do
#     get new_account_activation_url
#     assert_response :success
#   end
#
#   test "should create account_activation" do
#     assert_difference("AccountActivation.count") do
#       post account_activations_url, params: { account_activation: { email: @account_activation.email, token: @account_activation.token, user_id: @account_activation.user_id } }
#     end
#
#     assert_redirected_to account_activation_url(AccountActivation.last)
#   end
#
#   test "should show account_activation" do
#     get account_activation_url(@account_activation)
#     assert_response :success
#   end
#
#   test "should get edit" do
#     get edit_account_activation_url(@account_activation)
#     assert_response :success
#   end
#
#   test "should update account_activation" do
#     patch account_activation_url(@account_activation), params: { account_activation: { email: @account_activation.email, token: @account_activation.token, user_id: @account_activation.user_id } }
#     assert_redirected_to account_activation_url(@account_activation)
#   end
#
#   test "should destroy account_activation" do
#     assert_difference("AccountActivation.count", -1) do
#       delete account_activation_url(@account_activation)
#     end
#     assert_redirected_to account_activations_url
#     delete user_url(@user)
#   end
# end
