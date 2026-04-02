require "test_helper"
require "subsets"

class SubsetsTest < ActiveSupport::TestCase
  test "returns an enumerator when no block is given" do
    enum = Subsets.each_subset([1, 2, 3])
    assert_kind_of Enumerator, enum
  end

  test "yields subsets from largest to smallest" do
    got = Subsets.each_subset([1, 2, 3]).to_a
    assert_equal [1, 2, 3], got.first
    assert_equal [], got.last
  end

  test "yields subsets with elements sorted inside" do
    got = Subsets.each_subset([3, 1, 2]).to_a
    assert_equal [1, 2, 3], got.first
    assert_includes got, [1, 3]
    assert_includes got, [1, 2]
    assert_includes got, [2, 3]
    assert_includes got, [1]
    assert_includes got, [2]
    assert_includes got, [3]
    assert_includes got, []
  end

  test "dedupes input when dedupe: true" do
    got = Subsets.each_subset([1, 2, 2], dedupe: true).to_a
    assert_equal [[1, 2], [1], [2], []], got
  end

  test "does not dedupe input when dedupe: false" do
    got = Subsets.each_subset([1, 2, 2], dedupe: false).to_a
    assert_includes got, [1, 2, 2]
    assert_includes got, [2, 2]
  end

  test "empty input yields only empty subset" do
    got = Subsets.each_subset([]).to_a
    assert_equal [[]], got
  end

  test "single element yields [x] then []" do
    got = Subsets.each_subset([:a]).to_a
    assert_equal [[:a], []], got
  end

  test "works with non-array enumerables (range)" do
    got = Subsets.each_subset(1..3).to_a
    assert_equal [1, 2, 3], got.first
    assert_equal [], got.last
    assert_includes got, [2, 3]
  end
end
