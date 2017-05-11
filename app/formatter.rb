module App::Formatter
  def format_attrs(attrs, keys)
    "\n" + keys.map do |key|
      "#{attrs[key].to_s.blue}\n"
    end.join
  end
end