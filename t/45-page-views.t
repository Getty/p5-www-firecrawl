#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );

use WWW::Firecrawl;

# The policy (is_scrape_ok) is the leading view on a page; scrape_error only
# words what the policy found and never contradicts it.

my $not_found = { markdown => 'nope', metadata => { sourceURL => 'https://x/404', statusCode => 404 } };
my $gateway   = { metadata => { sourceURL => 'https://x/gw', statusCode => 502, error => 'bad gateway' } };
my $fine      = { markdown => 'ok', metadata => { sourceURL => 'https://x/ok', statusCode => 200 } };

subtest 'default policy: a 404 page without metadata.error is a success' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x' );
  ok $fc->is_scrape_ok($not_found), 'policy: ok';
  is $fc->scrape_error($not_found), undef, 'message: nothing to report';
  is $fc->scrape_status($not_found), 404, 'the status is still readable';
};

subtest 'default policy: a failed page is worded' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x' );
  ok !$fc->is_scrape_ok($gateway), 'policy: failed';
  is $fc->scrape_error($gateway), 'bad gateway (HTTP 502)', 'message names error and status';
  ok $fc->is_scrape_ok($fine), 'policy: ok';
  is $fc->scrape_error($fine), undef, 'no message for a good page';
};

subtest 'failure_codes: 404 fails by policy and is worded as such' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x', failure_codes => [404] );
  ok !$fc->is_scrape_ok($not_found), 'policy: failed';
  is $fc->scrape_error($not_found), 'HTTP 404', 'message agrees';
};

subtest 'any-non-2xx: 404 fails by policy and is worded as such' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x', failure_codes => 'any-non-2xx' );
  ok !$fc->is_scrape_ok($not_found), 'policy: failed';
  is $fc->scrape_error($not_found), 'HTTP 404', 'message agrees';
};

subtest 'strict follows the policy on a 404 page' => sub {
  my $resp = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    encode_json({ success => JSON::MaybeXS::true(), data => $not_found }) );

  my $default = WWW::Firecrawl->new( base_url => 'http://x', strict => 1 );
  is exception { $default->parse_scrape_response($resp) }, undef, 'default policy: no throw';

  my $codes = WWW::Firecrawl->new( base_url => 'http://x', strict => 1, failure_codes => [404] );
  my $e = exception { $codes->parse_scrape_response($resp) };
  isa_ok $e, 'WWW::Firecrawl::Error';
  ok $e->is_scrape, 'type scrape';
  like "$e", qr/HTTP 404/, 'message names the status';
};

subtest 'a custom policy decides, the message does not second-guess it' => sub {
  my $fc = WWW::Firecrawl->new( base_url => 'http://x', is_failure => sub { 0 } );
  ok $fc->is_scrape_ok($gateway), 'policy accepts the page';
  is $fc->scrape_error($gateway), undef, 'message stays silent';
};

done_testing;
