# Rodoo

A Ruby gem wrapping Odoo's JSON-RPC 2.0 API (Odoo v19+) with an Active Record-style interface.

## Requirements

- Ruby 3.0+
- Odoo v19 or higher (uses the `/json/2/` API endpoint)
- Odoo API key for authentication

## Installation

Add to your Gemfile:

```ruby
gem "rodoo"
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install rodoo
```

## Configuration

### Using environment variables

Rodoo automatically reads `ODOO_URL` and `ODOO_API_KEY` from the environment:

```bash
export ODOO_URL="https://your-instance.odoo.com"
export ODOO_API_KEY="your-api-key"
```

### Explicit configuration

```ruby
Rodoo.configure do |config|
  config.url = "https://your-instance.odoo.com"
  config.api_key = "your-api-key"
  config.timeout = 30          # Request timeout in seconds (default: 30)
  config.open_timeout = 10     # Connection timeout in seconds (default: 10)
  config.logger = Logger.new($stdout)
  config.log_level = :debug    # :info or :debug (default: :info)
end
```

## Usage

### Finding records

```ruby
# Find by ID
contact = Rodoo::Contact.find(42)
contact.name  # => "Acme Corp"
contact.email # => "contact@acme.com"

# Find by attributes
contact = Rodoo::Contact.find_by(email: "john@example.com")
contact = Rodoo::Contact.find_by(name: "Acme Corp", is_company: true)

# Find by string condition
contact = Rodoo::Contact.find_by("credit_limit > 1000")

# Find by raw domain
contact = Rodoo::Contact.find_by([["name", "ilike", "%acme%"]])

# Find by attributes (raises NotFoundError if not found)
contact = Rodoo::Contact.find_by!(email: "john@example.com")
```

### Querying records

Rodoo supports multiple query syntaxes for convenience:

```ruby
# Keyword arguments (equality)
companies = Rodoo::Contact.where(is_company: true)
active_companies = Rodoo::Contact.where(is_company: true, active: true)

# String conditions (parsed automatically)
high_credit = Rodoo::Contact.where("credit_limit > 1000")

# Multiple string conditions
filtered = Rodoo::Contact.where(["credit_limit > 1000", "active = true"])

# Raw Odoo domain syntax (for complex queries)
# See: https://www.odoo.com/documentation/19.0/developer/reference/backend/orm.html#reference-orm-domains
contacts = Rodoo::Contact.where([["name", "ilike", "%acme%"]])

# With pagination
contacts = Rodoo::Contact.where(is_company: true, limit: 10, offset: 20)

# Select specific fields
contacts = Rodoo::Contact.where(active: true, fields: ["name", "email"])

# Fetch all (with optional limit)
all_contacts = Rodoo::Contact.all(limit: 100)
```

Supported operators in string conditions: `=`, `!=`, `<>`, `<`, `>`, `<=`, `>=`, `like`, `ilike`, `=like`, `=ilike`

### Creating records

```ruby
# Create and persist immediately
contact = Rodoo::Contact.create(
  name: "New Contact",
  email: "new@example.com",
  is_company: false
)
contact.id  # => 123

# Build and save later
contact = Rodoo::Contact.new(name: "Draft Contact")
contact.email = "draft@example.com"
contact.save
```

### Updating records

```ruby
contact = Rodoo::Contact.find(42)

# Update specific attributes
contact.update(email: "updated@example.com", phone: "+1234567890")

# Or modify and save
contact.email = "another@example.com"
contact.save

# Reload from Odoo
contact.reload
```

### Deleting records

```ruby
contact = Rodoo::Contact.find(42)
contact.destroy

contact.destroyed?  # => true
```

### Available models

Rodoo includes pre-built models for common Odoo objects:

| Class | Odoo Model |
|-------|------------|
| `Rodoo::Contact` | `res.partner` |
| `Rodoo::Project` | `project.project` |
| `Rodoo::AnalyticAccount` | `account.analytic.account` |
| `Rodoo::AnalyticPlan` | `account.analytic.plan` |
| `Rodoo::AccountingEntry` | `account.move` (all types) |
| `Rodoo::CustomerInvoice` | `account.move` (move_type: out_invoice) |
| `Rodoo::ProviderInvoice` | `account.move` (move_type: in_invoice) |
| `Rodoo::CustomerCreditNote` | `account.move` (move_type: out_refund) |
| `Rodoo::ProviderCreditNote` | `account.move` (move_type: in_refund) |
| `Rodoo::JournalEntry` | `account.move` (move_type: entry) |

### Custom models

Create your own model by inheriting from `Rodoo::Model`:

```ruby
class Product < Rodoo::Model
  model_name "product.product"
end

# Use it like any other model
product = Product.find(1)
products = Product.where(type: "consu", limit: 10)
```

### Error handling

Rodoo provides a structured exception hierarchy:

```ruby
begin
  contact = Rodoo::Contact.find(999999)
rescue Rodoo::NotFoundError => e
  puts "Contact not found: #{e.message}"
rescue Rodoo::AuthenticationError => e
  puts "Invalid credentials"
rescue Rodoo::AccessDeniedError => e
  puts "Permission denied"
rescue Rodoo::ValidationError => e
  puts "Validation failed: #{e.message}"
rescue Rodoo::TimeoutError => e
  puts "Request timed out"
rescue Rodoo::ConnectionError => e
  puts "Connection failed: #{e.message}"
rescue Rodoo::APIError => e
  puts "API error: #{e.message} (code: #{e.code})"
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

```bash
rake test      # Run tests
rake rubocop   # Run linter
rake           # Run both
bin/console    # Interactive REPL
```

To install the gem locally:

```bash
bundle exec rake install
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dekuple/rodoo.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
