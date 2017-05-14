module App::Formatter
  def format_attrs(attrs, keys)
    attrs.select { |k,v| k.in? keys }.to_yaml
  end
end