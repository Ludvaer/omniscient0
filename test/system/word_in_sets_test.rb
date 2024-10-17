require "application_system_test_case"

class WordInSetsTest < ApplicationSystemTestCase
  setup do
    @word_in_set = word_in_sets(:one)
  end

  test "visiting the index" do
    visit word_in_sets_url
    assert_selector "h1", text: "Word in sets"
  end

  test "should create word in set" do
    visit word_in_sets_url
    click_on "New word in set"

    fill_in "Word", with: @word_in_set.word_id
    fill_in "Word set", with: @word_in_set.word_set_id
    click_on "Create Word in set"

    assert_text "Word in set was successfully created"
    click_on "Back"
  end

  test "should update Word in set" do
    visit word_in_set_url(@word_in_set)
    click_on "Edit this word in set", match: :first

    fill_in "Word", with: @word_in_set.word_id
    fill_in "Word set", with: @word_in_set.word_set_id
    click_on "Update Word in set"

    assert_text "Word in set was successfully updated"
    click_on "Back"
  end

  test "should destroy Word in set" do
    visit word_in_set_url(@word_in_set)
    click_on "Destroy this word in set", match: :first

    assert_text "Word in set was successfully destroyed"
  end
end
