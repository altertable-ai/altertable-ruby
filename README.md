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
Altertable.init('pk_live_abc123')

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
Altertable.init('pk_live_abc123', debug: true)
```

### Tracking Events

Record an action performed by a user.

`Altertable.track(event, distinct_id = nil, **options)`  
`Altertable.track(event_payload, **options)`  
`Altertable.track(event_payloads, **options)`

```ruby
Altertable.track('item_purchased', 'user_123', properties: {
  item_id: 'item_999',
  price: 19.99
})

Altertable.track({
  event: 'item_purchased',
  distinct_id: 'user_123',
  properties: { item_id: 'item_999', price: 19.99 }
})

Altertable.track([
  { event: 'signup', distinct_id: 'user_1', properties: { plan: 'pro' } },
  { event: 'login', distinct_id: 'user_2', timestamp: '2025-06-15T14:30:00.000Z' }
])
```

### Audience Measurement

Initialize with `mode: :audience` to collect events without identity fields:

```ruby
Altertable.init('pk_live_abc123', mode: :audience)
Altertable.track('Docs Opened', properties: { section: 'installation' })
```

Audience events send only `event`, `timestamp`, and `properties`; distinct, anonymous,
device, and session fields are dropped. `identify` and `alias` are ignored.
Requests come from your server, so they cannot distinguish browser visitors.

### Identifying Users

Link a user ID to their traits (like email or name).

`Altertable.identify(user_id, **options)`  
`Altertable.identify(identify_payload, **options)`  
`Altertable.identify(identify_payloads, **options)`

```ruby
Altertable.identify('user_123', traits: {
  email: 'user@example.com',
  name: 'John Doe'
})

Altertable.identify([
  { user_id: 'user_1', traits: { email: 'one@example.com' } },
  { user_id: 'user_2', traits: { email: 'two@example.com' } }
])
```

### Alias

Merge a previous anonymous ID with a newly identified user ID.

`Altertable.alias(distinct_id, new_user_id, **options)`  
`Altertable.alias(alias_payload, **options)`  
`Altertable.alias(alias_payloads, **options)`

```ruby
Altertable.alias('anon_session_456', 'user_123')

Altertable.alias([
  { distinct_id: 'anon_1', new_user_id: 'user_1' },
  { distinct_id: 'anon_2', new_user_id: 'user_2' }
])
```

A Hash payload posts one object; an Array posts a JSON array on the same endpoint. Omitted `timestamp` values default to the current time as ISO 8601.

## Configuration

You can configure the client by passing options during initialization.

| Option | Type | Default | Description |
|---|---|---|---|
| `mode` | Symbol, String | `:product` | Collection mode: `:product` or `:audience`. Fixed for the client lifetime. |
| `environment` | String | — | Deprecated and ignored. It is accepted for compatibility but never sent; use an environment-bound Product Analytics API key. |
| `base_url` | String | `"https://api.altertable.ai"` | Base URL for API requests. |
| `request_timeout` | Integer | `5` | Request timeout in seconds. |
| `release` | String | `nil` | Application release version (e.g., commit hash). |
| `debug` | Boolean | `false` | Enable debug logging. |
| `on_error` | Proc | `nil` | Callback for handling errors. |
| `adapter` | Symbol | auto-detect | HTTP adapter to use (`:faraday`, `:httpx`, `:net_http`). |
| `proxy` | String, Boolean | adapter default | Proxy to use for requests. Pass a URI string to force a specific proxy, or `false` to disable proxying (including any `HTTP_PROXY`/`HTTPS_PROXY` environment variables) for a fixed, trusted `base_url`. Unset by default: the `:faraday` and `:net_http` adapters auto-detect a proxy from the environment as they normally would; `:httpx` never does. |

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
