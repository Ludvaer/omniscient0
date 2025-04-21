class Dialect < ApplicationRecord
  @@by_name = Hash[Dialect.all.map { |d| [d.name,d.id]}]
  def find_by_name(name)
    @@by_name[name]
  end
end
