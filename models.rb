def add_patch_for_valid(klass)
  klass.class_exec do
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
end

class Job
  include DataMapper::Resource
  add_patch_for_valid(self)
  include App::Formatter

  validates_uniqueness_of :title

  def self.applied
    all status: "applied"
  end

  def self.uninterested
    all status: "uninterested"
  end

  def inspect
    format_attrs(public_attributes, %i{id title category comments tags})
  end

  def public_attributes
    attributes.merge(
      comments: comments.map(&:inspect),
      tags: tags.map(&:inspect)
    )
  end

  property :id, Serial
  property :title, String, unique: [:details], required: true
  property :details, Text
  property :category, String
  property :status, String
  property :source, String

  has n, :job_links, 'JobLink',
    child_key: [:job_id],
    parent_key: [:id]

  has n, :pages, 'Page',
    through: :job_links,
    via: :page

  has n, :comments, "Comment",
    child_key: [:job_id],
    parent_key: [:id]

  has n, :tags, "Tag",
    child_key: [:job_id],
    parent_key: [:id]

end
 
class JobLink
  include App::Formatter
  def inspect
    format_attrs(attributes, %i{id})
  end
  include DataMapper::Resource
  add_patch_for_valid(self)
  property :id, Serial
  property :page_id, Integer
  property :job_id, Integer

  belongs_to :page
  belongs_to :job
end

class Page

  include App::Formatter

  def inspect
    format_attrs(attributes, %i{id title url})
  end

  include DataMapper::Resource
  add_patch_for_valid(self)

  property :id,         Serial
  property :url,      String
  property :title,       String
  property :abstract, Text
  property :created_at, DateTime

  has n, :tags
  has n, :comments

  has n, :job_links, 'JobLink',
    parent_key: [:id],
    child_key: [:page_id]

  has n, :page_links, 'PageLink',
    parent_key: [:id],
    child_key: [:page_id]

  has n, :page_linkbacks, 'PageLink',
    parent_key: [:id],
    child_key: [:linked_id]

  has n, :linked, self,
    through: :page_links,
    via: :linked

  has n, :linkbacks, self,
    through: :page_linkbacks,
    via: :page

  def self.create_from_google_hit(hit, custom_attrs={})
    create({
      url: hit.url, title: hit.title, abstract: hit.abstract
    }.merge custom_attrs)
  end

  def self.by_tag(name)
    all(tags: [{name: name}])
  end

end

class Tag

  include App::Formatter

  def inspect
    format_attrs(attributes, %i{id name})
  end

  include DataMapper::Resource
  add_patch_for_valid(self)

  property :id,         Serial
  property :page_id,      Integer
  property :job_id, Integer
  property :name,       String
  property :created_at, DateTime

  belongs_to :page
  belongs_to :job

  def pages
    Page.all(tags: [id: id])
  end

  def jobs
    Job.all(tags: [id: id])
  end
  
end

class Comment

  include App::Formatter

  def inspect
    format_attrs(attributes, %i{id content})
  end

  include DataMapper::Resource
  add_patch_for_valid(self)
  property :id,         Serial
  property :page_id,      Integer
  property :job_id, Integer
  property :content,       String
  property :created_at, DateTime

  belongs_to :page
  belongs_to :job

end

class PageLink

  include App::Formatter

  def inspect
    format_attrs(attributes, %i{id})
  end

  include DataMapper::Resource
  add_patch_for_valid(self)
  property :id, Serial
  property :page_id, Integer
  property :linked_id, Integer
  property :created_at, DateTime

  belongs_to :page
  belongs_to :linked, 'Page',
    parent_key: [:id],
    child_key: [:linked_id],
    required: true

end  

DataMapper.finalize
DataMapper.auto_upgrade!
