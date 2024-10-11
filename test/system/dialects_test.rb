require "application_system_test_case"

class DialectsTest < ApplicationSystemTestCase
  setup do
    @dialect = dialects(:one)
  end

  test "visiting the index" do
    visit dialects_url
    assert_selector "h1", text: "Dialects"
  end

  test "should create dialect" do
    visit dialects_url
    click_on "New dialect"

    fill_in "Language", with: @dialect.language_id
    fill_in "Name", with: @dialect.name
    click_on "Create Dialect"

    assert_text "Dialect was successfully created"
    click_on "Back"
  end

  test "should update Dialect" do
    visit dialect_url(@dialect)
    click_on "Edit this dialect", match: :first

    fill_in "Language", with: @dialect.language_id
    fill_in "Name", with: @dialect.name
    click_on "Update Dialect"

    assert_text "Dialect was successfully updated"
    click_on "Back"
  end

  test "should destroy Dialect" do
    visit dialect_url(@dialect)
    click_on "Destroy this dialect", match: :first

    assert_text "Dialect was successfully destroyed"
  end
end
