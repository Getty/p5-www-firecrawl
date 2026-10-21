---
name: www-firecrawl-core
description: "Load when working on WWW::Firecrawl — the synchronous Perl bindings for the Firecrawl v2 API. The three endpoint flavours, the five error types, the classification policy (is_failure/failure_codes), the retry contract and the flow-helper shapes are the contracts callers depend on."
---

# WWW::Firecrawl — the contracts

`WWW-Firecrawl` is a thin, synchronous binding for the Firecrawl v2 HTTP API. It has
no state, no cache and no logic of its own beyond transport, decoding, error
classification and retry. Everything a caller can rely on is listed here.

The service side (the self-hosted instance, cloud keys, the endpoint catalogue) lives in
skill `perl-firecrawl`. Do not repeat it here.

## Module map

| File | Holds |
|---|---|
| `lib/WWW/Firecrawl.pm` | everything: attributes, request builders, parsers, convenience methods, retry, flow helpers |
| `lib/WWW/Firecrawl/Error.pm` | the error class; overloads to a string, always true |
| `t/*.t` | nine test files: load, requests, responses, error class, classification, strict, retry, scrape_many, retry_failed_pages |

There is no script, no `bin/`, no second module. `Net::Async::Firecrawl` (sibling repo)
is built on the request builders and parsers of this module.

## The three flavours

Every endpoint exists three times:

| Flavour | Signature | Does |
|---|---|---|
| builder | `$fc->foo_request(%args)` | returns an `HTTP::Request`; no I/O |
| parser | `$fc->parse_foo_response($http_response)` | decodes JSON, dies on error, returns the payload |
| convenience | `$fc->foo(%args)` | builds, fires via `LWP::UserAgent`, parses |

The convenience flavour is `parse_foo_response($fc->_do_with_retry($fc->foo_request))`.
A new endpoint needs all three; the parser is the piece other code reuses.

Endpoint families: `scrape` (plus `scrape_execute`, `scrape_browser_stop`), `crawl`
(+ `crawl_status`, `crawl_cancel`, `crawl_errors`, `crawl_active`,
`crawl_params_preview`, `crawl_status_next`), `map`, `search`, `batch_scrape` (+
`batch_scrape_status`, `_cancel`, `_errors`, `_status_next`), `extract` (+
`extract_status`), `agent` (+ `agent_status`, `agent_cancel`), `browser` (+
`browser_create`, `_list`, `_delete`, `_execute`), `credit_usage` (+ `_historical`),
`token_usage` (+ `_historical`), `queue_status`, `activity`.

## The error model

Everything that fails throws `WWW::Firecrawl::Error` — never a bare string. The
`type` attribute is the vocabulary callers switch on:

| Type | Means |
|---|---|
| `transport` | Firecrawl was not reached (DNS/connect/TLS/socket) or answered with `Client-Warning: Internal response` |
| `api` | non-2xx HTTP, invalid JSON, or a payload with `success => false` |
| `job` | a flow's job ended in a failure state (polling helpers) |
| `scrape` | a single scrape whose target was classified as failed under `strict` |
| `page` | a single page inside a bulk flow that was classified as failed |

The class carries `message`, `response`, `data`, `status_code`, `url` and `attempt`.
Predicates `is_transport`, `is_api`, `is_job`, `is_scrape`, `is_page` exist.

`parse_response` is the single place where `api` errors are raised: non-2xx → dies,
invalid JSON → dies, `success => false` → dies. A successful response returns the
decoded payload unchanged.

## The classification policy

Whether a *scraped page* counts as failed is a policy decision, not an HTTP decision.
It is configured with `is_failure` (a callback) or `failure_codes` (a list of status
codes) — the two are mutually exclusive, `BUILDARGS` croaks if both are given.

The default (`is_failure` unset) counts a page as failed when `metadata.error` is set
**or** `metadata.statusCode >= 500`. `failure_codes` accepts the string
`any-non-2xx` or an arrayref of status codes.

Two ways of judging the same page exist and they do not agree everywhere:

- `is_scrape_ok($page)` — the policy; `!is_failure->($page)`.
- `scrape_error($page)` — the message; `metadata.error`, or `"HTTP $sc"` for any
  status outside 200..299, otherwise `undef`.

A page that scraped a 404 is a failure by `scrape_error` but a success by the default
policy. Decide which question you are asking before you branch on either.

`strict` (default off) applies the policy to a single `scrape`: a page classified as
failed makes `scrape` die with a `scrape`-type error instead of returning the payload.

## The retry contract

`max_attempts` (3), `retry_backoff` ([1,2,4]), `retry_statuses` ([429,502,503,504]),
`on_retry`, `sleep_sub` (defaults to `Time::HiRes::sleep`).

A response is retried when it is not successful and its status is in `retry_statuses`;
transport errors are classified separately and are not retried through the status list.
The delay is `Retry-After` when that header is a plain integer, otherwise
`retry_backoff->[attempt-1]`, clamped to the last entry. `on_retry` is called with
(`$attempt`, `$delay`, `$error`) before the sleep. The last attempt's error is thrown.

## Flow helpers and their shapes

`scrape_many(\@urls, %common)` runs strictly sequentially, one request per URL, and
returns `{ ok => [ {url, data} ], failed => [ {url, error} ], stats => {ok, failed,
total} }`. A URL that throws lands in `failed` with the error object; a URL whose page
is classified as failed lands in `failed` with a `page`-type error.

`retry_failed_pages($result, %scrape_opts)` takes exactly that shape: it reads
`$result->{failed}` and re-scrapes those URLs. It knows nothing about a crawl job —
handing it a raw `crawl()` result yields an empty run, because a job payload has no
`failed` key. The async client has the matching split (`_split_pages`); the sync
client has no equivalent.

`crawl_status_next` / `batch_scrape_status_next` follow the `next` URL from the
payload verbatim, including its query string.

## Attributes

`base_url` (`$ENV{FIRECRAWL_BASE_URL}`, default the cloud URL), `api_key`
(`$ENV{FIRECRAWL_API_KEY}`), `api_version` (`v2`), `json` (a `JSON::MaybeXS` codec),
`user_agent_string`, `ua` (an `LWP::UserAgent`, timeout 300), `is_failure`,
`failure_codes`, `strict`, `max_attempts`, `retry_backoff`, `retry_statuses`,
`on_retry`, `sleep_sub`.

## Traps

- `use URI ()` is loaded and never used, and `URI` is not in the `cpanfile` — a
  `use`d-but-undeclared module is a broken build for everyone without it locally.
- `scrape_status` and `scrape_error` read `$page->{metadata}{…}` and therefore
  autovivify `metadata` in a hash the caller passed in.
- `parse_response` returns the payload as-is — it does not check whether a scrape
  succeeded. Only the classification policy does that.
- The convenience methods swallow nothing: a failing endpoint dies, it does not
  return an error value.
- `failure_codes` and `is_failure` cannot be combined.
- `dist.ini` uses `[@Author::GETTY]`, and that bundle aborts the build when no
  `LICENSE` file is committed.

## Tests

`prove -lr t/` — nine files, 66 tests, no network and no live instance: the tests
build requests and feed crafted `HTTP::Response` objects into the parsers. Keep it
that way; a test that needs Firecrawl running is a test nobody runs.

## Vocabulary

**Flavour** — one of the three shapes of an endpoint. **Job** — a long-running
Firecrawl operation (`crawl`, `batch_scrape`, `extract`, `agent`) that returns an id
and is polled with a `*_status` endpoint. **Page** — one scraped document, with
`metadata` (and possibly `error`) inside. **Classification** — the policy deciding
whether a page is a failure. **Transport error** — the request never produced an HTTP
answer. **API error** — Firecrawl answered, but not successfully.
