You are assisting with Fastladder, an open-source RSS/Atom feed reader.

## Project Overview
- **Framework**: Ruby on Rails 8.1 / Ruby 3.4
- **Database**: SQLite (default), MySQL/PostgreSQL optional
- **Frontend**: Hotwire (Turbo/Stimulus) + legacy LDR JavaScript
- **Architecture**: Web process + Crawler process (foreman)

## Development Guidelines
- Prefer simple, explicit code over clever abstractions.
- Follow Rails conventions and RESTful design.
- Avoid introducing new gems unless explicitly requested.
- Keep changes minimal and localized.
- Use minitest for testing (not RSpec).
- Use fixtures and TestDataHelper for test data (not FactoryBot).

## Key Constraints
- Turbo Drive is globally disabled (to avoid conflicts with legacy LDR JS).
- Crawler must be idempotent and use transactions.
- External HTTP calls must be stubbed in tests (WebMock).

## File Structure
- `app/` - Rails application code
- `lib/fastladder/` - Crawler components (Fetcher, FeedParser, CrawlerReporter)
- `script/crawler` - Crawler entry point
- `app/javascript/controllers/` - Stimulus controllers
- `docs/modernization/` - Migration plan and baseline notes

## Commands
```sh
foreman start           # Run web + crawler
bin/rails test          # Run tests
bin/ci                  # Run full CI locally
bundle exec rubocop -A  # Auto-fix style issues
```
