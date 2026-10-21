# WWW-Firecrawl

Perl bindings for the Firecrawl v2 HTTP API: scrape, crawl, map, search, batch scrape,
extract, agent, browser and the usage endpoints. Self-hosted first — the cloud API works
too, but the module defaults to a plain base URL and API key, nothing Firecrawl-specific.

Released to CPAN as `WWW-Firecrawl`, built with `Dist::Zilla` via `[@Author::GETTY]`.
Two modules — `WWW::Firecrawl` holds everything, `WWW::Firecrawl::Error` is the error
class it throws — and no script.

Every endpoint comes in three flavours (request builder, response parser, convenience
method); the sibling distribution `Net-Async-Firecrawl` is built on the builder and the
parser. The endpoint contract, the error model and the classification and retry policy
live in skill `www-firecrawl-core` — they are not repeated here.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
the principle and the lane boundaries are in `.claude/rules/www-firecrawl-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `www-firecrawl-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `www-firecrawl-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/` —
`getty-perl-core`, `getty-perl-moo`, `getty-perl-pod` and the karr skills are installed
from the shared sources; `www-firecrawl-core` and `perl-firecrawl` are owned by this repo.

Work is coordinated on the repo's `karr` board (`karr board`).

## State of the code

The distribution works and its tests are green (`prove -lr t/`), but it predates the
current house structures: there is no `LICENSE` file, so `dzil build` aborts, and there
is no CI. The known gaps are tracked on the internal board.
