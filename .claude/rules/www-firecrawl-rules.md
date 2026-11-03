# WWW-Firecrawl House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Firecrawl v2 API bindings (self-host first, cloud compatible). Both modules carry `our $VERSION`;
the bundle writes it at release through `[RewriteVersion::Transitional]` and
`[BumpVersionAfterRelease]`. Prerequisites live in `cpanfile`, `dist.ini` holds the header
and the bundle.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `www-firecrawl-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `www-firecrawl-release-manager` |
| Read-only research, audit, gap analysis | `www-firecrawl-worker` ("read-only, change nothing") |

Behavior-relevant = anything in `lib/`, the tests, the endpoint methods and their three
flavours, the error types, the classification and retry policy. Docs wording is not.

## Hazards — the binding contract is the product

- **Don't regress it silently.** Every endpoint exists as `foo_request` (builds the request, no
  I/O), `parse_foo_response` (decodes the response) and `foo` (both). Failures are thrown as
  `WWW::Firecrawl::Error` with the types transport/api/job/scrape/page; a string thrown instead
  breaks the contract. Whether a page counts as failed is decided by the `is_failure` policy,
  not by the HTTP status of the scrape call. A test that can't fail when the three flavours, the
  error types or the classification policy change is not a test. Contract table: skill
  `www-firecrawl-core`.
- **The sibling builds on it.** `Net-Async-Firecrawl` is built on the request builder and the
  parser — a change there changes that distribution too.
- **A new dependency needs a real justification.**

## Perl specifics — reference, don't restate

Perl conventions live in `getty-perl-core` / `getty-perl-moo` / `getty-perl-pod`, the endpoint
contract in `www-firecrawl-core`.
