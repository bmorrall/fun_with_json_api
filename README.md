# FunWithJsonApi

Provides a DSL for converting json_api into active model parameters, with a sprinking of json_api validation, and a lot of semantically correct json api error responses.

[![Build Status](https://travis-ci.org/bmorrall/fun_with_json_api.svg?branch=master)](https://travis-ci.org/bmorrall/fun_with_json_api)
[![Gem Version](https://badge.fury.io/rb/fun_with_json_api.svg)](https://badge.fury.io/rb/fun_with_json_api)

## Deserializer

With a User Deserializer:

```
class UserDeserializer < FunWithJsonApi::Deserializer
  type 'people'
  resource_class User
end
```

and an Article Deserializer:

```
class ArticlesDeserializer < FunWithJsonApi::Deserializer
  resource_class Article

  attribute :title

  has_one :author, -> { UserDeserializer }
end
```

Calling `FunWithJsonApi.deserialize(params, ArticlesDeserializer)` within a controller,
will convert:

```
{
  "type": "articles",
  "attributes": {
    "title": "Rails is Omakase"
  },
  "relationships": {
    "author": {
      "data": { "type": "people", "id": "9" }
    }
  }
}
```

Into parameters than can create an `Article`:

```
{
  title: "Rails is Omakase",
  author_id: 9
}
```

Or calling `FunWithJsonApi.deserialize_resource(params, ArticlesDeserializer, article)`,
when the Article has an id of '24', it will convert:

```
{
  "id": '24'
  "type": "articles",
  "attributes": {
    "title": "Rails is Omakase"
  },
  "relationships": {
    "author": {
      "data": { "type": "people", "id": "9" }
    }
  }
}
```

into parameters that can update the Article, or it will raise an exception with the correct http
status and I18n debugging information.

## Find Resource

With a User Deserializer:

```
class UserDeserializer < FunWithJsonApi::Deserializer
  type 'people'
  resource_class User
end
```

and a document referencing a existing User:

```
{
  "data": { "id": "42", "type": "people" }
}
```

Calling `FunWithJsonApi.find_resource(params, UserDeserializer)`, will return the User.

A document with an empty data attribute:

```
{
  "data": null
}
```

will return `nil`. This method is very useful for defining a has_one or belongs_to relationship
controller.

## Attributes

Attributes are declared within a Deserializer class. i.e.

```
class ExampleDeserializer < FunWithJsonApi::Deserializer
  attribute :foo
end
```

### Attribute Aliases

They can be renamed by adding an 'as:' argument:

`attribute :foo, as: :bar`

Will convert an json_api attribute with the key `foo` into a parameter with the key `bar`, ie:

```
{
  data: {
    ...
    attributes: {
      foo: 'example'
    }
  }
}

=> { bar: 'example' }
```

### Attribute Formats

Attributes can be coerced into a expected Ruby Object, by providing a 'format:' argument:

`attribute :foo, format: :integer`

Will allow any integer attribute value for `foo`, a string that can be parsed into an integer,
or `null`, but will not allow any non-numerical characters (i.e "bar", 'twenty two' or '12,000.10')

The following formats can be provided to an attribute, and will be coerced into the expected
Ruby Object.

| Attribute Type      | Format      | Ruby Object        | Example                                |
| ------------------- | ----------- | ------------------ | -------------------------------------- |
| string              | :string     | String             | 'Lorem ipsum dolor sit amet..          |
| text                | :string     | String             | 'Lorem ipsum dolor sit amet..          |
| boolean             | :boolean    | Boolean.TRUE/FALSE | true, false                            |
| date                | :date       | Date               | '2016-03-12'                           |
| datetime (ISO 8601) | :datetime   | DateTime           | '2016-03-12T16:33:17+11:00'            |
| decimal             | :decimal    | BigDecimal         | 123.45                                 |
| float               | :float      | Float              | 12.34                                  |
| integer             | :integer    | Integer            | 12                                     |
| uuid (RFC 4122 v4)  | :uuid_v4    | String             | '624f6dd0-91f2-4026-a684-01924da4be84' |

## Exceptions

FunWithJsonApi includes a `render_fun_with_json_api_exception` helper method,
this generally includes an expanded payload with additional debugging information,
while protecting the API from revealing its internal workings.

You can handle most json api exceptions with the following code:

```
class ApplicationController < ActionController::Base
  include FunWithJsonApi::ControllerMethods

  rescue_from FunWithJsonApi::Exception, with: :render_fun_with_json_api_exception
end
```

## License

This project rocks and uses MIT-LICENSE.
