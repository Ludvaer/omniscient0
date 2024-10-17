# require "test_helper"
#
# class WordInSetsControllerTest < ActionDispatch::IntegrationTest
#   setup do
#     @word_in_set = word_in_sets(:one)
#   end
#
#   test "should get index" do
#     get word_in_sets_url
#     assert_response :success
#   end
#
#   test "should get new" do
#     get new_word_in_set_url
#     assert_response :success
#   end
#
#   test "should create word_in_set" do
#     assert_difference("WordInSet.count") do
#       post word_in_sets_url, params: { word_in_set: { word_id: @word_in_set.word_id, word_set_id: @word_in_set.word_set_id } }
#     end
#
#     assert_redirected_to word_in_set_url(WordInSet.last)
#   end
#
#   test "should show word_in_set" do
#     get word_in_set_url(@word_in_set)
#     assert_response :success
#   end
#
#   test "should get edit" do
#     get edit_word_in_set_url(@word_in_set)
#     assert_response :success
#   end
#
#   test "should update word_in_set" do
#     patch word_in_set_url(@word_in_set), params: { word_in_set: { word_id: @word_in_set.word_id, word_set_id: @word_in_set.word_set_id } }
#     assert_redirected_to word_in_set_url(@word_in_set)
#   end
#
#   test "should destroy word_in_set" do
#     assert_difference("WordInSet.count", -1) do
#       delete word_in_set_url(@word_in_set)
#     end
#
#     assert_redirected_to word_in_sets_url
#   end
# end
