# Altertable Ruby SDK

Official Ruby SDK for Altertable Product Analytics.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'altertable-ruby'
```

And then execute:

    $ bundle install

## Usage

### Initialization

```ruby
require 'altertable'

Altertable.init('your_api_key', {
  environment: 'production'
})
```

### Tracking Events

```ruby
Altertable.track('button_clicked', 'user_123', properties: {
  button_id: 'signup_btn',
  page: 'home'
}, timestamp: Time.now.utc.iso8601)
```

### Identifying Users

```ruby
Altertable.identify('user_123', traits: {
  email: 'user@example.com',
  name: 'John Doe'
}, anonymous_id: 'previous_anon_id')
```

### Alias

```ruby
Altertable.alias('previous_anonymous_id', 'new_user_id')
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
