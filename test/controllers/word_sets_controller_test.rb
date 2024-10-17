# require "test_helper"
#
# class WordSetsControllerTest < ActionDispatch::IntegrationTest
#   setup do
#     @word_set = word_sets(:one)
#   end
#
#   test "should get index" do
#     get word_sets_url
#     assert_response :success
#   end
#
#   test "should get new" do
#     get new_word_set_url
#     assert_response :success
#   end
#
#   test "should create word_set" do
#     assert_difference("WordSet.count") do
#       post word_sets_url, params: { word_set: {  } }
#     end
#
#     assert_redirected_to word_set_url(WordSet.last)
#   end
#
#   test "should show word_set" do
#     get word_set_url(@word_set)
#     assert_response :success
#   end
#
#   test "should get edit" do
#     get edit_word_set_url(@word_set)
#     assert_response :success
#   end
#
#   test "should update word_set" do
#     patch word_set_url(@word_set), params: { word_set: {  } }
#     assert_redirected_to word_set_url(@word_set)
#   end
#
#   test "should destroy word_set" do
#     assert_difference("WordSet.count", -1) do
#       delete word_set_url(@word_set)
#     end
#
#     assert_redirected_to word_sets_url
#   end
# end
