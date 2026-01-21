# Fastladder

[![Test](https://github.com/fastladder/fastladder/actions/workflows/test.yml/badge.svg)](https://github.com/fastladder/fastladder/actions/workflows/test.yml)

Fastladder is the best solution for feed-hungry people who want to consume more RSS/Atom feeds, and this is its open-source version.
The open-source Fastladder, so called OpenFL, is an RSS reader to be installed on your PC or server with a capability to handle RSS feeds available within your Intranet.

## Requirements

- Ruby 3.4.8+
- Rails 8.1.2+
- SQLite 3.x (default) or MySQL/PostgreSQL

## Quick Start

```sh
git clone https://github.com/fastladder/fastladder.git
cd fastladder
bin/setup
foreman start
```

Open http://localhost:5000 in your browser.

## Setup

### Using SQLite (Recommended)

```sh
git clone https://github.com/fastladder/fastladder.git
cd fastladder
bin/setup
```

### Using MySQL

```sh
cp config/database.yml.mysql config/database.yml
# Edit config/database.yml with your MySQL credentials
bundle install
bin/rails db:create db:migrate
```

### Using PostgreSQL

```sh
cp config/database.yml.postgresql config/database.yml
# Edit config/database.yml with your PostgreSQL credentials
bundle install
bin/rails db:create db:migrate
```

## Run

Fastladder consists of two processes: **web** and **crawler**.

### Using foreman (Recommended)

```sh
foreman start         # Run both web and crawler
foreman start web     # Run web only
foreman start crawler # Run crawler only
```

### Running processes separately

```sh
# Web server (default: http://localhost:3000)
bin/rails server

# Crawler (fetches feeds periodically)
bundle exec ruby script/crawler
```

## Development

### Running tests

```sh
bin/rails test          # Unit and integration tests
bin/rails test:system   # System tests (requires Chrome)
```

### Running CI locally

```sh
bin/ci
```

This runs:
- `bin/setup` - Install dependencies and prepare database
- `bundle-audit` - Security audit for gems
- `brakeman` - Static security analysis
- `rubocop` - Code style checks
- `rails test` - Unit and integration tests
- `rails test:system` - System tests

### Code style

```sh
bundle exec rubocop        # Check style
bundle exec rubocop -A     # Auto-correct issues
```

## Docker

Docker Compose setup uses MySQL as the database.

```sh
docker-compose up
```

Open http://localhost:5000 in your browser.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Fastladder                          │
├─────────────────────────┬───────────────────────────────┤
│      Web Process        │      Crawler Process          │
│   (bin/rails server)    │  (script/crawler)             │
│                         │                               │
│  - User interface       │  - Fetches RSS/Atom feeds     │
│  - Feed management      │  - Parses feed content        │
│  - Reading articles     │  - Stores items in DB         │
│  - API endpoints        │  - Runs periodically          │
└─────────────────────────┴───────────────────────────────┘
                          │
                    ┌─────┴─────┐
                    │  SQLite   │
                    │ Database  │
                    └───────────┘
```

## License

Fastladder is released under the MIT License.
