class Page
  include DataMapper::Resource

  property :id,         Serial
  property :url,      String
  property :title,       String
  property :abstract, Text
  property :created_at, DateTime

  def self.create_from_google_hit(hit)
    create url: hit.url, title: hit.title, abstract: hit.abstract
  end

end

class Tag
  include DataMapper::Resource

  property :id,         Serial
  property :url,      String
  property :name,       String
  property :created_at, DateTime
  
end

class Comment
  include DataMapper::Resource
  property :id,         Serial
  property :url,      String
  property :content,       String
  property :created_at, DateTime
end

DataMapper.finalize
DataMapper.auto_upgrade!