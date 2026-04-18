# WWW::Firecrawl

Perl bindings for the [Firecrawl](https://firecrawl.dev) v2 API — self-hosted first, cloud compatible.

## Synopsis

```perl
use WWW::Firecrawl;

# Self-hosted
my $fc = WWW::Firecrawl->new( base_url => 'http://localhost:3002' );

# Cloud
my $fc = WWW::Firecrawl->new( api_key => 'fc-...' );

# Scrape
my $doc = $fc->scrape( url => 'https://example.com', formats => ['markdown'] );
print $doc->{markdown};

# Crawl
my $job    = $fc->crawl( url => 'https://example.com', limit => 50 );
my $status = $fc->crawl_status( $job->{id} );

# Map
my $links = $fc->map( url => 'https://example.com' );

# Search
my $results = $fc->search( query => 'perl async', limit => 5 );

# Scrape many URLs (partial-success: ok + failed + stats)
my $batch = $fc->scrape_many(
  ['https://a', 'https://b', 'https://c'],
  formats => ['markdown'],
);

# Retry failed pages from a crawl
my $retried = $fc->retry_failed_pages( $crawl_result );
```

## Three-Flavour API

Every endpoint has three variants — no UA lock-in:

```perl
# 1. Build the request (no I/O)
my $req = $fc->scrape_request( url => 'https://example.com' );

# 2. Parse a response (no I/O)
my $data = $fc->parse_scrape_response($http_response);

# 3. Convenience: build + fire + parse via LWP
my $data = $fc->scrape( url => 'https://example.com' );
```

For async use, see [Net::Async::Firecrawl](../p5-net-async-firecrawl).

## Error Handling

All errors throw a `WWW::Firecrawl::Error` object (stringifies to message):

```perl
use eval { $fc->scrape(...) };
if (my $e = $@) {
  if (ref $e && $e->isa('WWW::Firecrawl::Error')) {
    if ($e->is_api)       { ... }  # Firecrawl rejected the request
    if ($e->is_transport) { ... }  # couldn't reach Firecrawl
    if ($e->is_scrape)    { ... }  # target URL failed (strict mode)
  }
}
```

Five types: `transport`, `api`, `job`, `scrape`, `page`.

**Strict mode** — throw when the target URL itself fails (default: off):

```perl
my $fc = WWW::Firecrawl->new( strict => 1 );
# or per-call:
$fc->scrape( url => 'https://example.com', strict => 1 );
```

**Classification policy** — what counts as a target failure:

```perl
# default: metadata.error set OR statusCode >= 500
my $fc = WWW::Firecrawl->new( failure_codes => [404, 500..599] );
my $fc = WWW::Firecrawl->new( failure_codes => 'any-non-2xx' );
my $fc = WWW::Firecrawl->new( is_failure => sub { my ($page) = @_; ... } );
```

**Retry** — automatic on transport failures and 429/502/503/504:

```perl
my $fc = WWW::Firecrawl->new(
  max_attempts  => 3,
  retry_backoff => [1, 2, 4],   # seconds
  on_retry      => sub { my ($attempt, $delay, $error) = @_ },
);
```

## Environment

| Variable | Purpose |
|---|---|
| `FIRECRAWL_BASE_URL` | Default `base_url` (overridden by constructor) |
| `FIRECRAWL_API_KEY` | Default `api_key` (overridden by constructor) |

## Installation

```bash
cpanm WWW::Firecrawl
# or from source:
cpanm --installdeps .
```

## See Also

- [Net::Async::Firecrawl](https://metacpan.org/pod/Net::Async::Firecrawl) — IO::Async integration
- [Firecrawl API docs](https://docs.firecrawl.dev/api-reference/v2-introduction)
- [Firecrawl on GitHub](https://github.com/mendableai/firecrawl)
