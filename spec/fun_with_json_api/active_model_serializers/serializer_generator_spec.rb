require 'spec_helper'

describe FunWithJsonApi::ActiveModelSerializers::SerializerGenerator do
  describe '.call' do
    it 'generates a active model serializer from a AuthorDeserializer' do
      author = ARModels::Author.create(
        id: 42, code: 'person_12', name: Faker::Name.name
      )
      ARModels::Post.create(
        id: 24, author_id: 42
      )

      deserializer = ARModels::AuthorDeserializer.create
      serializer_class = described_class.call(deserializer)

      options = {}
      serializer = serializer_class.new(author, options)

      adapter_options = {}
      adapter = ::ActiveModelSerializers::Adapter::JsonApi.new(serializer, adapter_options)

      expect(adapter.as_json).to eq(
        data: {
          id: author.code,
          type: 'person',
          attributes: {
            name: author.name
          },
          relationships: {
            posts: {
              data: [
                { id: '24', type: 'posts' }
              ]
            }
          }
        }
      )
    end

    it 'generates a active model serializer from a PostDeserializer' do
      author = ARModels::Author.create(
        id: 42, code: 'person_12', name: Faker::Name.name
      )
      post = ARModels::Post.create(
        id: 24, author_id: 42, title: Faker::Company.name, body: Faker::Lorem.sentence
      )
      ARModels::Comment.create(
        id: 1, post_id: 24, contents: 'Comment 1'
      )
      ARModels::Comment.create(
        id: 2, post_id: 24, contents: 'Comment 2'
      )

      deserializer = ARModels::PostDeserializer.create
      serializer_class = described_class.call(deserializer)

      options = {}
      serializer = serializer_class.new(post, options)

      adapter_options = { include: 'author, comments' }
      adapter = ::ActiveModelSerializers::Adapter::JsonApi.new(serializer, adapter_options)

      expect(adapter.as_json).to eq(
        data: {
          id: post.id.to_s,
          type: 'posts',
          attributes: {
            title: post.title,
            body: post.body
          },
          relationships: {
            author: {
              data: { id: 'person_12', type: 'person' }
            },
            comments: {
              data: [
                { id: '1', type: 'comments' },
                { id: '2', type: 'comments' }
              ]
            }
          }
        },
        included: [
          {
            id: '1',
            type: 'comments',
            attributes: {
              contents: 'Comment 1'
            }
          },
          {
            id: '2',
            type: 'comments',
            attributes: {
              contents: 'Comment 2'
            }
          },
          {
            id: 'person_12',
            type: 'person',
            attributes: {
              name: author.name
            }
          }
        ]
      )
    end
  end
end
