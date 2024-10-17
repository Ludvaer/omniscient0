require "application_system_test_case"

class WordSetsTest < ApplicationSystemTestCase
  setup do
    @word_set = word_sets(:one)
  end

  test "visiting the index" do
    visit word_sets_url
    assert_selector "h1", text: "Word sets"
  end

  test "should create word set" do
    visit word_sets_url
    click_on "New word set"

    click_on "Create Word set"

    assert_text "Word set was successfully created"
    click_on "Back"
  end

  test "should update Word set" do
    visit word_set_url(@word_set)
    click_on "Edit this word set", match: :first

    click_on "Update Word set"

    assert_text "Word set was successfully updated"
    click_on "Back"
  end

  test "should destroy Word set" do
    visit word_set_url(@word_set)
    click_on "Destroy this word set", match: :first

    assert_text "Word set was successfully destroyed"
  end
end
