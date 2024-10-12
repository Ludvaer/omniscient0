# require "test_helper"
#
# class ShultesControllerTest < ActionDispatch::IntegrationTest
#   setup do
#     @shulte = shultes(:one)
#   end
#
#   test "should get index" do
#     get shultes_url
#     assert_response :success
#   end
#
#   test "should get new" do
#     get new_shulte_url
#     assert_response :success
#   end
#
#   test "should create shulte" do
#     assert_difference("Shulte.count") do
#       post shultes_url, params: { shulte: { mistakes: @shulte.mistakes, shuffle: @shulte.shuffle, size: @shulte.size, time: @shulte.time, user_id: @shulte.user_id } }
#     end
#
#     assert_redirected_to shulte_url(Shulte.last)
#   end
#
#   test "should show shulte" do
#     get shulte_url(@shulte)
#     assert_response :success
#   end
#
#   test "should get edit" do
#     get edit_shulte_url(@shulte)
#     assert_response :success
#   end
#
#   test "should update shulte" do
#     patch shulte_url(@shulte), params: { shulte: { mistakes: @shulte.mistakes, shuffle: @shulte.shuffle, size: @shulte.size, time: @shulte.time, user_id: @shulte.user_id } }
#     assert_redirected_to shulte_url(@shulte)
#   end
#
#   test "should destroy shulte" do
#     assert_difference("Shulte.count", -1) do
#       delete shulte_url(@shulte)
#     end
#
#     assert_redirected_to shultes_url
#   end
# end
