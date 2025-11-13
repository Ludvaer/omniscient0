class Dialect < ApplicationRecord
  has_many :words
  @@by_name = Hash[Dialect.all.map { |d| [d.name,d]}]

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

  def self.by_name(name)
    @@by_name[name]
  end

  private
end
