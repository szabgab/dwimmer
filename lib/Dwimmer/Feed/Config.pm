package Dwimmer::Feed::Config;
use strict;
use warnings;

my %DEFAULT;

sub get_config_hash {
	my ($self, $db) = @_;

	return $db->get_config_hash;
}

sub get_config {
	my ($self, $db) = @_;

	my $config = $db->get_config;
}

sub get {
	my ($self, $db, $field) = @_;

	my $config = $db->get_config_hash;
	return $config->{$field} // $DEFAULT{$field};
}


$DEFAULT{atom_tt} = q{
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">

<title>[% title %]</title>
<subtitle>[% subtitle %]></subtitle>
<link href="[% url %]"/>
<id>[% id %]</id>
<updated>[% last_build_date %]</updated>

<author>
  <name>[% admin_name %]</name>
  <email>[% admin_email %]</email>
</author>
<generator uri="http://search.cpan.org/dist/Dwimmer/" version="[% dwimmer_version %]">Dwimmer</generator>

[% FOR e IN entries %]
<entry>
  <author>
     <name>[% e.author_name %]</name>
     <uri>[% e.author_uri %]</uri>
  </author>
  <title>[% e.title %]</title>
  <link href="[% e.link %]"/>
  <id>[% e.id %]</id>
  <updated>[% e.issued %]</updated>
  <published>[% e.issued %]</published>
  <summary><![CDATA[[% e.display %]]]></summary>
</entry>
[% END %]

</feed>
};

$DEFAULT{rss_tt} = q{
<?xml version="1.0"?>
<?xml-stylesheet title="CSS_formatting" type="text/css" href="http://www.interglacial.com/rss/rss.css"?>
<rss version="2.0"><channel>

<link>[% url %]</link>
<title>[% title %]</title>
<description>[% description %]</description>
<language>[% language %]</language>
<lastBuildDate>[% last_build_date %]</lastBuildDate>
<webMaster>[% admin_email %]</webMaster>

<docs>http://www.interglacial.com/rss/about.html</docs>

[% FOR e IN entries %]
<item>
  <title>[% e.title %]</title>
  <link>[% e.link %]</link>
  <description><![CDATA[[% e.display %]]]></description>
  <dc:date>[% e.issued %]</dc:date>
</item>
[% END %]

</channel></rss>
};

$DEFAULT{index_tt} = q{
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en-us">
<head>
<title>Perlsphere - the Perl blog aggregator</title>
 <link href="/rss.xml" rel="alternate" type="application/rss+xml" title ="Perlsphere RSS Feed" />
 <link href="/atom.xml" rel="alternate" type="application/atom+xml" title ="Perlspehere ATOM Feed" />
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

 <script type="text/javascript" src="https://apis.google.com/js/plusone.js"></script>
</head>
<body>
<style>
html {
  margin: 0;
  padding: 0;
}
body {
  margin: 0;
  padding: 0;
  /* text-align: center;*/
  width: 800px;
  margin-left: auto;
  margin-right: auto;
  font-size: 16px;

}
#header_text {
}

.entry {
  background-color: #DDD;
  padding: 10px;
  margin-top: 10px;
  margin-bottom: 10px;

  -moz-border-radius: 5px;
  -webkit-border-radius: 5px;
  border: 1px solid #000;

  min-height: 220px;
  height:auto !important;
  min-height: 220px;
}

.left {
  width: 675px;
  position: relative;
  background-color: #EEEEEE;

  padding: 5px;

  -moz-border-radius: 5px;
  -webkit-border-radius: 5px;
  border: 1px solid #000;

}

.entry_info {
  margin-top: 10px;
  width: 675px;
  background-color: #E4E4E4;
  padding: 5px;
  -moz-border-radius: 5px;
  -webkit-border-radius: 5px;
  border: 1px solid #000;
}

.social_link {
  float: right;
  position: relative;
  width: 70px;
  background-color: #DFDFDF;
  text-align: center;

  padding: 5px;
  -moz-border-radius: 5px;
  -webkit-border-radius: 5px;
  border: 1px solid #000;

}


.title {
  font-size: 24px;
  font-weight: bold;
}
.title a {
   text-decoration: none;
}
</style>


  <h1>Perlsphere</h1>
  <div id="header_text">
  The Perl firehose! The Web's biggest collection of Perl blogs.
  If you'd like your Perl blog or tech blog's Perl category to appear here, send mail to szabgab@gmail.com
  (Please have several posts already). <a href="/feeds.html">feeds</a>.
  </div>

[% FOR e IN entries %]
  <div class="entry">

    <div class="social_link">
        <a href="http://twitter.com/share" class="twitter-share-button"
         data-text="[% e.title %]" data-url="[% e.link %]" data-count="vertical" data-via="szabgab">Tweet</a>
        <script type="text/javascript" src="http://platform.twitter.com/widgets.js">
        </script>

      <script>reddit_url='[% e.link %]'</script>
      <script>reddit_title='[% e.title %]'</script>
      <script type="text/javascript" src="http://reddit.com/button.js?t=2"></script>


       <g:plusone size="tall" href="[% e.link %]"></g:plusone>

<!--
        <a name="fb_share" type="box_count" class="fb_share"
        share_url="[% e.link %]">Share</a>
         <script src="http://static.ak.fbcdn.net/connect.php/js/FB.Share" type="text/javascript"></script>
-->

    </div>

    <div class="left">
    <div class="source"><a href="[% e.source_url %]">[% e.source_name %]</a></div>
    <div class="title"><a href="[% e.link %]">[% e.title %]</a></div>
    <div class="summary">
    [% e.display %]
    </div>
    </div>
    <div class="entry_info">
    <div class="date">Posted on [% e.issued %]</div>
    <div class="permalink">For the full article visit <a href="[% e.link %]">[% e.title %]</a></div>
    </div>
  </div>
[% END %]

<div>
<div>
Last updated: [% last_update %]
</div>
</div>
[% track %]
</body>
</html>
};


$DEFAULT{feeds_tt} = q{
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en-us">
<head>
<title>Perlsphere - the Perl blog aggregator</title>
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
<style>
html {
  margin: 0;
  padding: 0;
}
body {
  margin: 0;
  padding: 0;
  /* text-align: center;*/
  width: 800px;
  margin-left: auto;
  margin-right: auto;
  font-size: 16px;

}
#header_text {
}

.entry {
  background-color: #DDD;
  padding: 10px;
  margin-top: 10px;
  margin-bottom: 10px;

  -moz-border-radius: 5px;
  -webkit-border-radius: 5px;
  border: 1px solid #000;

}
.title {
  font-size: 24px;
  font-weight: bold;
}
.title a {
   text-decoration: none;
}
</style>


  <h1>Perlsphere feeds</h1>
  <a href="/">home</a>

[% FOR e IN entries %]
  <div class="entry">
  <div class="title"><a href="[% e.url %]">[% e.title %]</a></div>
  [% IF e.twitter %]
     <div class="twitter"><a href="https://twitter.com/#!/[% e.twitter %]">@[% e.twitter %]</a></div>
  [% END %]
  <div class="latest">Latest: <a href="[% e.latest_entry.link %]">[% e.latest_entry.title %]</a> on [% e.latest_entry.issued %]</div>
  </div>
[% END %]

</div>
[% track %]
</body>
</html>
};



1;
