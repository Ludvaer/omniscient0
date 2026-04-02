module Subsets
  module_function

  def each_subset(enum, dedupe: false)
    arr = enum.to_a
    arr = arr.uniq if dedupe
    arr = arr.sort

    return enum_for(__method__, enum, dedupe: dedupe) unless block_given?

    arr.length.downto(0) do |k|
      arr.combination(k) { |combo| yield combo }
    end
  end
end
