require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.string :title
    t.text :body
    t.references :author
    t.timestamps null: false
  end
  create_table :authors, force: true do |t|
    t.string :name
    t.string :code
    t.timestamps null: false
  end
  create_table :comments, force: true do |t|
    t.text :contents
    t.references :author
    t.references :post
    t.timestamps null: false
  end
end

module ARModels
  class Post < ActiveRecord::Base
    has_many :comments
    belongs_to :author
  end

  class Comment < ActiveRecord::Base
    belongs_to :post
    belongs_to :author
  end

  class Author < ActiveRecord::Base
    has_many :posts
  end

  class PostDeserializer < FunWithJsonApi::Deserializer
    resource_class Post

    attribute :title
    attribute :body

    has_many :comments, -> { CommentDeserializer }
    belongs_to :author, -> { AuthorDeserializer }
  end

  class CommentDeserializer < FunWithJsonApi::Deserializer
    resource_class Comment

    attribute :contents

    belongs_to :author, -> { AuthorDeserializer }
  end

  class AuthorSerializer < ::ActiveModel::Serializer
    type 'person'

    attribute :name

    has_many :posts
  end

  class AuthorDeserializer < FunWithJsonApi::Deserializer
    type 'person'
    id_param :code
    resource_class Author

    attribute :name

    has_many :posts, -> { PostDeserializer }
  end
end
