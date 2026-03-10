# Altertable Ruby SDK

[![Build Status](https://github.com/altertable-ai/altertable-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/altertable-ai/altertable-ruby/actions)
[![Gem Version](https://badge.fury.io/rb/altertable.svg)](https://rubygems.org/gems/altertable)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Official Ruby SDK for Altertable Product Analytics.

## Install

Install the gem with a single command:

```bash
gem install altertable
```

## Quick Start

Initialize the client and track your first event. Call `track()` to record an action a user performed.

```ruby
require 'altertable'

# Initialize the Altertable client
Altertable.init('pk_live_abc123', environment: 'production')

# Track an event
Altertable.track('button_clicked', 'user_123', properties: {
  button_id: 'signup_btn',
  page: 'home'
})
```

## API Reference

### Initialization

Initialize the global Altertable client instance.

`Altertable.init(api_key, options = {})`

```ruby
Altertable.init('pk_live_abc123', environment: 'production', debug: true)
```

### Tracking Events

Record an action performed by a user.

`Altertable.track(event, distinct_id, **options)`

```ruby
Altertable.track('item_purchased', 'user_123', properties: {
  item_id: 'item_999',
  price: 19.99
})
```

### Identifying Users

Link a user ID to their traits (like email or name).

`Altertable.identify(user_id, **options)`

```ruby
Altertable.identify('user_123', traits: {
  email: 'user@example.com',
  name: 'John Doe'
})
```

### Alias

Merge a previous anonymous ID with a newly identified user ID.

`Altertable.alias(distinct_id, new_user_id, **options)`

```ruby
Altertable.alias('anon_session_456', 'user_123')
```

## Configuration

You can configure the client by passing options during initialization.

| Option | Type | Default | Description |
|---|---|---|---|
| `environment` | String | `"production"` | Environment name (e.g., `production`, `development`). |
| `base_url` | String | `"https://api.altertable.ai"` | Base URL for API requests. |
| `request_timeout` | Integer | `5` | Request timeout in seconds. |
| `release` | String | `nil` | Application release version (e.g., commit hash). |
| `debug` | Boolean | `false` | Enable debug logging. |
| `on_error` | Proc | `nil` | Callback for handling errors. |
| `adapter` | Symbol | auto-detect | HTTP adapter to use (`:faraday`, `:httpx`, `:net_http`). |

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
