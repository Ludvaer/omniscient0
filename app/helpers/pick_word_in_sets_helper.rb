module PickWordInSetsHelper
  def new_pick_word_in_set_url_from_names(source, target, option)
    source_dialect_id = Dialect.find_by(name: source.downcase)
    target_dialect_id = Dialect.find_by(name: target.downcase)
    option_dialect_id = Dialect.find_by(name: option.downcase)
    url = new_pick_word_in_set_url(params: {n: 10, source_dialect_id: source_dialect_id, \
      target_dialect_id: target_dialect_id, option_dialect_id: option_dialect_id})
    cap = "[#{source.capitalize} >>> #{target.capitalize}]: pick #{option.capitalize}"
    link_to(cap, url)
  end
end
