class DataBaseCacheService
  CACHE_KEY_PREFIX = "data_base_cache_service"

  def initialize(source_dialect_id, target_dialect_id)
    @source_dialect_id = source_dialect_id
    @target_dialect_id =  target_dialect_id
  end

  def self.translation_max_rank(source_dialect_id, target_dialect_id)
    DataBaseCacheService.new(source_dialect_id,target_dialect_id).translation_max_rank
  end

  def translation_max_rank # TODO: Add job to refresh cache when db is updated
    Rails.cache.fetch( \
      "#{CACHE_KEY_PREFIX}/trans_max_rank?s=#{@source_dialect_id}&t=#{@target_dialect_id}", \
       expires_in: nil) do \
          Translation.joins(:word) \
            .where(word:{dialect_id: @target_dialect_id}, translation_dialect_id: @source_dialect_id) \
            .maximum(:rank)
    end
  end
end
