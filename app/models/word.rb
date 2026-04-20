require 'subsets'

class Word < ApplicationRecord
  belongs_to :dialect
  has_many :translations

  def self.max_rank(target_dialect)
    puts('word max_rank called')
    Rails.cache.fetch("word/max_rank?target=" + target_dialect.name, expires_in: nil ) do
          Word.where(dialect: target_dialect).pluck(:rank).max
    end
  end

  def self.existing_japanese_by_key()
    existing_by_key(Dialect.japanese.id)
  end
  #jap words are defined by key with jap word and it's readings
  #this returns dictionary by such key with | deliminator and
  #and words with preloaded translations as value
  #TODO: rework that, there is no reason to use this string keys in ruby, use dicts / arrays
  def self.existing_by_key(dialect_from)
    result = Word.eager_load(:translations)\
      .where(dialect_id: dialect_from)\
      .group_by{|w| (w.spelling or '_') + "|" + w.translations.where(translation_dialect_id: Dialect.kana.id)&.pluck(:translation)\
        .map{|t|t.split(' ')[0]}.uniq.sort.join('|')&.to_s}
    result.sort_by{|key,ws|key.length}.each do |key,ws|
      readings = ws.map{|w|w.translations.where(translation_dialect_id: Dialect.kana.id).pluck(:translation)}.flatten
      spellings = ws.map{|w|w.translations.where(translation_dialect_id: Dialect.japanese.id).pluck(:translation)}.flatten
      ws.each{|w| spellings.append(w.spelling)}
      next unless spellings
      spellings.filter!{|s|!s.blank?}
      spellings.uniq!
      spellings.sort!
      spellings.each do |spelling|
        Subsets.each_subset(readings).each do |readings_subset|
          key =  spelling + "|" + readings_subset.sort.join('|')
          result[key] ||= ws
        end
      end
    end
    return result
  end
end
