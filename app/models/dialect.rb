class Dialect < ApplicationRecord
  has_many :words
  @@by_name = Hash[Dialect.all.map { |d| [d.name,d]}]
  @@by_id = Hash[Dialect.all.map { |d| [d.id,d]}]
  def self.kana
    @@kana ||= by_name('kana')
  end

  def self.japanese
    @@japanese ||= by_name('japanese')
  end

  def self.english
    @@english ||= by_name('english')
  end

  def self.russian
    @@russian ||= by_name('russian')
  end

  def self.kanji
    @@kanji ||= by_name('kanji')
  end

  def self.by_name(name)
    @@by_name[name]
  end

  def self.by_id(id)
    @@by_id[id]
  end

  private
end
