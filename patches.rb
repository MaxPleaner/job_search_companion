
# This is present in ruby 2.5 or newer, and backported here
module Kernel
  def yield_itself(&blk)
    blk.call self
  end
end

module DataMapper::Resource

  # make valid? print something when it fails
  # disabled via the SilentMode env var
  def valid?(*args)
    result = super(*args)
    unless result
      log errors.full_messages.join(", "), :red
    end
    result
  end

end

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

class Hash
  
  def map_values(&blk)
    # blk is passed and returns a val
    reduce({}) do |memo, (key, val)|
      memo.tap { memo[key] = blk.call(val) }
    end
  end
  
  def map_keys(&blk)
    # blk is passed and returns a key
    reduce({}) do |memo, (key, val)|
      memo.tap { memo[blk.call key] = val }
    end
  end

  def map_keyvals(&blk)git
    # blk is passed key/val and returns [key, val]
    reduce({}) do |memo, (key, val)|
    end
  end

end

class Hash
end

Thread.abort_on_exception = true