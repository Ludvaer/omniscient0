class PickWordInSet < ApplicationRecord
  belongs_to :translation_set
  belongs_to :user
  belongs_to :correct, :class_name => 'Translation'
  belongs_to :picked, :class_name => 'Translation', optional: true
  attr_readonly :correct_id
  attr_readonly :version
  attr_readonly :translation_set_id
  attr_readonly :user_id
  attr_accessor :test_type_id
  MAX_PICKS_PER_REQUEST =100
  # I discarded this way providing kana translation through fake attributes but if i ever need this stuff works
  # alias_method :parent_preloadable_attributes, :preloadable_attributes

  # def self.preloadable_fake_references
  #   return {additional: 'Translation'}
  # end
  #
  # def preloadable_attributes
  #   # kanaDialect = Dialect.find_by(name: 'kana')
  #   # word_id = self.correct.word.id
  #   # additional = Translation.joins(:word).find_by(word:{id:word_id}, translation_dialect_id: kanaDialect.id)
  #   unless additional.nil?
  #     return parent_preloadable_attributes.merge({ additional_id: additional&.id}) #TOFO: make it additional column?
  #   end
  #   return parent_preloadable_attributes
  # end

  # def additional
  #   kanaDialect = Dialect.find_by(name: 'kana')
  #   word_id = self.correct.word.id
  #   unless kanaDialect.nil?
  #     return Translation.joins(:word).find_by(word:{id:word_id}, translation_dialect_id: kanaDialect.id)
  #   end
  #   return nil
  # end

  def self.create(params)
    return PickWordInSetService.create(params)
  end



end
