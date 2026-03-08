# Contributing to altertable-ruby

## Development Setup

1. Fork and clone the repository
2. Install dependencies: `bundle install`
3. Run tests: `bundle exec rspec`

## Making Changes

1. Create a branch from `main`
2. Make your changes
3. Add or update tests
4. Run the full check suite: `bundle exec rake`
5. Commit using [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, etc.)
6. Open a pull request

## Code Style

This project uses `RuboCop` for linting and formatting. Run `bundle exec rubocop` before committing.

## Tests

- Unit tests are required for all new functionality
- Integration tests run in CI when credentials are available
- Run tests locally: `bundle exec rspec`

## Pull Requests

- Keep PRs focused on a single change
- Update `CHANGELOG.md` under `[Unreleased]`
- Ensure CI passes before requesting review