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

Product analytics is the default. Select audience measurement when creating a client:

```ruby
Altertable.init('pk_live_abc123', mode: :audience)
Altertable.track('Docs Opened', properties: {
  '$url' => 'https://example.com/docs?campaign=launch',
  '$referer' => 'https://search.example/results?q=docs',
  section: 'installation'
})
Altertable.track({ event: 'Install Copied', properties: { package: 'ruby' } })
Altertable.track([{ event: 'Docs Opened' }, { event: 'Install Copied' }])
```

Audience events send only `mode: "audience"`, `event`, `timestamp`, and `properties`.
No `distinct_id`, `anonymous_id`, `device_id`, `session_id`, or `environment` is sent,
even if supplied by the caller. The API key determines the audience environment.
`identify` and `alias` return `nil` without sending a request, including for hash
and batch inputs. Enable `debug: true` during development to warn about these calls.

The SDK reduces `$url` to its HTTP(S) origin and path, reduces `$referer` to its
origin, and removes `$viewport`. Credentials, query strings, and fragments are
removed from these built-in URLs; invalid or unsupported URLs become `nil`.
Both symbol and string property keys are supported. Library/version and configured
release metadata are retained. Custom properties and URL paths can still contain
personal information: callers are responsible for choosing appropriate values.

Mode is fixed for each `Altertable::Client`. Create a new client or call
`Altertable.init` again to change it. Per-event options cannot override mode.
Both `:product`/`:audience` and `"product"`/`"audience"` are accepted; other values
raise `Altertable::ConfigurationError` before replacing the global client.

This server SDK sends requests immediately. It has no persistent identity,
sessions, disk queue, consent manager, automatic page capture, or event transforms.
Failed requests are not queued for replay across clients. Gate calls according to
your application's consent policy. All HTTP transports (`:faraday`, `:httpx`, and
`:net_http`) are supported; their existing timeout, proxy, and retry behavior applies.

Audience visitor hashing on the backend uses the IP address and User-Agent of the
SDK's HTTP request, which describe your server rather than the end user's browser.
Server-side audience events therefore cannot reliably measure distinct end-user
visitors. This SDK does not forward end-user IP/User-Agent headers.

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
| `environment` | String | `"production"` | Product environment name (e.g., `production`, `development`). Omitted in audience mode; the API key selects its environment. |
| `base_url` | String | `"https://api.altertable.ai"` | Base URL for API requests. |
| `request_timeout` | Integer | `5` | Request timeout in seconds. |
| `release` | String | `nil` | Application release version (e.g., commit hash). |
| `debug` | Boolean | `false` | Enable debug logging. |
| `on_error` | Proc | `nil` | Callback for handling errors. |
| `adapter` | Symbol | auto-detect | HTTP adapter to use (`:faraday`, `:httpx`, `:net_http`). |
| `proxy` | String, Boolean | adapter default | Proxy to use for requests. Pass a URI string to force a specific proxy, or `false` to disable proxying (including any `HTTP_PROXY`/`HTTPS_PROXY` environment variables) for a fixed, trusted `base_url`. Unset by default: the `:faraday` and `:net_http` adapters auto-detect a proxy from the environment as they normally would; `:httpx` never does. |

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
