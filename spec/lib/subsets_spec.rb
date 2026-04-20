RSpec.describe Subsets do
  describe ".each_subset" do
    it "returns an enumerator when no block is given" do
      enum = described_class.each_subset([1, 2, 3])
      expect(enum).to be_a(Enumerator)
    end

    it "yields subsets from largest to smallest" do
      got = described_class.each_subset([1, 2, 3]).to_a
      expect(got.first).to eq([1, 2, 3])
      expect(got.last).to eq([])
    end

    it "yields subsets with elements sorted inside" do
      got = described_class.each_subset([3, 1, 2]).to_a
      expect(got.first).to eq([1, 2, 3])
      expect(got).to include([1, 3], [2], [])
    end

    it "dedupes input when dedupe: true" do
      got = described_class.each_subset([1, 2, 2], dedupe: true).to_a
      expect(got).to eq([
        [1, 2],
        [1],
        [2],
        []
      ])
    end

    it "does not dedupe input when dedupe: false" do
      got = described_class.each_subset([1, 2, 2], dedupe: false).to_a
      # We should see a subset that includes both 2s
      expect(got).to include([1, 2, 2], [2, 2])
    end
  end
end
