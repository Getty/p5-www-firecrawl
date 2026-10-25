#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );

use WWW::Firecrawl;

{
  package Test::CountUA;
  sub new { bless { requests => [], reply => $_[1] }, $_[0] }
  sub request { push @{ $_[0]{requests} }, $_[1]; return $_[0]{reply} }
  sub count { scalar @{ $_[0]{requests} } }
}

sub json_response {
  my ($data) = @_;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    encode_json($data) );
}

# Real job results, as the parsers hand them out.
my $started = json_response({ success => JSON::MaybeXS::true(), id => 'job-1', url => 'http://x/v2/crawl/job-1' });
my $status  = json_response({
  status => 'completed', total => 2, completed => 2,
  data => [
    { markdown => 'a', metadata => { sourceURL => 'https://a', statusCode => 200 } },
    { metadata => { sourceURL => 'https://b', statusCode => 503, error => 'timeout' } },
  ],
});

my $ua = Test::CountUA->new($started);
my $fc = WWW::Firecrawl->new( base_url => 'http://x', ua => $ua, sleep_sub => sub { } );

my $job = $fc->crawl( url => 'https://a' );
is $job->{id}, 'job-1', 'crawl() returns the job payload';

my $e = exception { $fc->retry_failed_pages($job) };
like $e, qr/retry_failed_pages: .*failed/, 'crawl() payload is refused with a message';
like $e, qr/scrape_many/, 'the message names the expected input';
is $ua->count, 1, 'nothing was re-scraped';

my $page = $fc->parse_crawl_status_response($status);
is $page->{status}, 'completed', 'crawl_status() payload';
like exception { $fc->retry_failed_pages($page) }, qr/retry_failed_pages: .*failed/,
  'crawl_status() payload is refused too';

like exception { $fc->retry_failed_pages() }, qr/retry_failed_pages: /, 'undef is refused';
like exception { $fc->retry_failed_pages([]) }, qr/retry_failed_pages: /, 'an arrayref is refused';
like exception { $fc->retry_failed_pages({ failed => 'x' }) }, qr/retry_failed_pages: /,
  'failed must be an arrayref';
like exception { $fc->retry_failed_pages({ failed => [ { error => 'x' } ] }) },
  qr/retry_failed_pages: .*url/, 'failed entries need a url';

my $none = $fc->retry_failed_pages({ ok => [], failed => [] });
is_deeply $none->{stats}, { ok => 0, failed => 0, total => 0 }, 'an empty failed[] is a valid, empty run';

done_testing;
