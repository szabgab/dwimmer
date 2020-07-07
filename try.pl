use strict;
use warnings;
use 5.010;
use XML::Feed;
use URI;

# Just to see if the XML::Feed module can parse the feed

my ($feed_url) = @ARGV;
die "Usage: $0 FEED\n" if not $feed_url;

my $feed = XML::Feed->parse(URI->new($feed_url));
if (not $feed) {
    die XML::Feed->errstr;
}

say $feed->title;
