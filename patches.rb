class String

  # facets
  def lchomp(match="\n")
    if index(match) == 0
      self[match.size..-1]
    else
      self.dup
    end
  end
end
