# Altertable Ruby SDK

You can use this SDK to send Product Analytics events to Altertable from Ruby applications.

## Install

```bash
gem install altertable
```

## Quick start

```ruby
require 'altertable'

Altertable.init('pk_live_abc123', environment: 'production')

Altertable.track('button_clicked', 'user_123', properties: {
  button_id: 'signup_btn',
  page: 'home'
})
```

## API reference

### Initialization

`Altertable.init(api_key, options = {})`

Initializes the global client instance.

```ruby
Altertable.init('pk_live_abc123', debug: true)
```

### Tracking

`Altertable.track(event, distinct_id, **options)`

Sends an event for a user.

```ruby
Altertable.track('purchase', 'user_123', properties: { amount: 19.99 })
```

### Identity

`Altertable.identify(user_id, **options)`

Associates traits with a user.

```ruby
Altertable.identify('user_123', traits: { email: 'user@example.com' })
```

### Alias

`Altertable.alias(distinct_id, new_user_id, **options)`

Merges an anonymous identifier into a known user identifier.

```ruby
Altertable.alias('anon_456', 'user_123')
```

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `environment` | `String` | `"production"` | Environment name (for example `production` or `development`). |
| `base_url` | `String` | `"https://api.altertable.ai"` | API base URL. |
| `request_timeout` | `Integer` | `5` | Request timeout in seconds. |
| `release` | `String \| nil` | `nil` | Application release version. |
| `debug` | `Boolean` | `false` | Enables debug logging. |
| `on_error` | `Proc \| nil` | `nil` | Error callback hook. |
| `adapter` | `Symbol` | auto-detect | HTTP adapter (`:faraday`, `:httpx`, `:net_http`). |

## Development

Prerequisites: Ruby 3.1+ and Bundler.

```bash
bundle install
bundle exec rake spec
bundle exec rubocop
```

## License

See [LICENSE](LICENSE).