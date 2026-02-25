# Wallet App

A small Rails service that implements simple wallet-to-wallet transfers with idempotency and strong consistency.

Key points
- Rails API with a single resource: POST /api/v1/transfers
- Uses integer balances stored in cents
- Transfer logic in `app/services/transfer_service.rb` — atomic DB transaction with row locking
- MySQL (mysql2) as the database adapter

Tech stack
- Ruby (see Gemfile). Rails ~ 8.1.1
- MySQL (mysql2 gem)
- RSpec for tests

Features
- Create transfers between wallets.
- Handles insufficient funds, same-wallet errors, and idempotency via an `idempotency_key` field on Transfer.

Prerequisites
- Ruby (use a version compatible with Rails 8.x — Ruby 3.2+ is recommended)
- Bundler
- MySQL server (or compatible) and credentials configured in `config/database.yml`

Quick start (development, macOS / zsh)

1. Clone the repo

	 git clone <repo-url>
	 cd wallet_app

2. Install dependencies

	 gem install bundler
	 bundle install

3. Configure the database

	 - Edit `config/database.yml` with your local MySQL credentials.
	 - Create and migrate the database:

		 bin/rails db:create db:migrate

4. Start the server

	 bin/rails server -b 0.0.0.0 -p 3000

API: Create a transfer

Endpoint

POST /api/v1/transfers

Request formats supported: application/json (also accepts form data).

Parameters
- from_wallet_id: integer (required)
- to_wallet_id: integer (required)
- amount: string/decimal (required) — the amount in major units (e.g. "10.50"). Internally converted to cents.
- idempotency_key: string (optional but recommended) — used to ensure idempotent transfers

Example (curl)

	curl -X POST http://localhost:3000/api/v1/transfers \
		-H "Content-Type: application/json" \
		-d '{"transfer": {"from_wallet_id": 1, "to_wallet_id": 2, "amount":"10.50", "idempotency_key":"unique-key-123"}}'

Successful response (HTTP 200)

	{ "message": "Success" }

Error responses
- 404 Not Found: when one of the wallet ids doesn't exist
- 422 Unprocessable Entity: for business errors (insufficient balance, same wallet, or other validation)

Notes about implementation
- Amounts are converted to integer cents inside `TransferService#convert_to_cents`.
- Transfers run inside an ActiveRecord transaction and use row-level locking (`Wallet.lock`) to avoid race conditions.
- The code creates a `Transfer` record with `status: :completed` on success.
- There's a unique index on the transfers table to support idempotency (see db/migrate files).

Running tests

	bundle exec rspec
