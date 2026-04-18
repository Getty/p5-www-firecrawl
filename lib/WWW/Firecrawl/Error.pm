package WWW::Firecrawl::Error;
# ABSTRACT: structured error class for WWW::Firecrawl
use Moo;
use overload
  '""' => sub { $_[0]->message },
  bool => sub { 1 },
  fallback => 1;

our $VERSION = '0.002';

has type        => ( is => 'ro', required => 1 );
has message     => ( is => 'ro', required => 1 );
has response    => ( is => 'ro' );
has data        => ( is => 'ro' );
has status_code => ( is => 'ro' );
has url         => ( is => 'ro' );
has attempt     => ( is => 'ro' );

sub is_transport { $_[0]->type eq 'transport' }
sub is_api       { $_[0]->type eq 'api' }
sub is_job       { $_[0]->type eq 'job' }
sub is_scrape    { $_[0]->type eq 'scrape' }
sub is_page      { $_[0]->type eq 'page' }

1;

=head1 SYNOPSIS

  die WWW::Firecrawl::Error->new(
    type        => 'api',
    message     => "HTTP 503: Service Unavailable",
    response    => $http_response,
    status_code => 503,
    attempt     => 3,
  );

  if (my $e = $@) {
    if (ref $e && $e->isa('WWW::Firecrawl::Error')) {
      warn "firecrawl failed at @{[ $e->type ]}: $e" if $e->is_api;
    }
  }

=attr type

One of C<transport>, C<api>, C<job>, C<scrape>, C<page>. Required.

=attr message

Human-readable error string. Required. The object stringifies to this.

=attr response

The L<HTTP::Response> object, when available.

=attr data

The decoded JSON payload, when available.

=attr status_code

For C<transport>/C<api> this is the HTTP status code of the Firecrawl response
(0 for pure transport failures). For C<scrape>/C<page> this is
C<data.metadata.statusCode> of the target page. Undef for C<job>.

=attr url

Target URL for C<scrape> and C<page> errors.

=attr attempt

1-based attempt counter, populated when retry was involved.

=method is_transport

=method is_api

=method is_job

=method is_scrape

=method is_page

Boolean accessors, each returns true when L</type> matches.

=cut
