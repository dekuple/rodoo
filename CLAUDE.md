# CLAUDE.md

Rodoo is a Ruby gem wrapping Odoo's JSON-RPC 2.0 API (Odoo v19+) with an Active Record-style interface.

## Commands

```bash
rake test      # Run tests
rake rubocop   # Run linter
rake           # Run both
bin/console    # Interactive REPL
```

## Architecture

- `lib/rodoo.rb` - Module entry point, global configuration via `Rodoo.configure`, singleton connection via `Rodoo.connection`
- `lib/rodoo/configuration.rb` - Settings: url, api_key, timeout, open_timeout, logger, log_level (reads ODOO_URL/ODOO_API_KEY from env)
- `lib/rodoo/connection.rb` - HTTP transport, posts to `/json/2/{model}/{method}`, maps Odoo errors to Ruby exceptions
- `lib/rodoo/model.rb` - Base class with query methods (find, where, all, find_by, create) and persistence (save, update, reload)
- `lib/rodoo/errors.rb` - Exception hierarchy: Error → ConfigurationError, ConnectionError (→ TimeoutError), APIError (→ AuthenticationError, NotFoundError, ValidationError, AccessDeniedError)
- `lib/rodoo/models/` - Concrete models: Contact, Project, AnalyticAccount, AnalyticPlan, and accounting entries (CustomerInvoice, ProviderInvoice, CustomerCreditNote, ProviderCreditNote, JournalEntry via AccountingEntry base)

## Testing

Minitest with mocked connections. Test files in `test/` mirror lib structure.
