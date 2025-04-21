module PickWordInSetsHelper
  def new_pick_word_in_set_url_from_names(target, display, option)
    # source_dialect_id = Dialect.find_by(name: source.downcase)
    # target_dialect_id = Dialect.find_by(name: target.downcase)
    # option_dialect_id = Dialect.find_by(name: option.downcase)
    url = new_pick_word_in_set_url(params: {n: 10, target: target, \
      display: display, option: option})
    display = display.kind_of?(Array) ? display.map{|d|d.capitalize}.to_s : display.capitalize
    cap = "#{target.capitalize}: [#{display} >>> #{option.capitalize}]"
    link_to(cap, url)
  end
end
