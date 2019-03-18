
[![Build Status](https://travis-ci.org/szabgab/dwimmer.png)](https://travis-ci.org/szabgab/dwimmer)

Dwimmer is an experiment.

It started as a blog engine with this screencast: http://www.youtube.com/watch?v=NGX5pgKWVoc
but since then it is all kinds of things.

For example it is a wiki, a CMS, a planet...
or a beginnnig of either of those.

Mostly it is an experiment to write some stuff.

=================================================
Setup:

If you already have a CPAN enabled perl installed then type "cpan Dwimmer" in your command prompt.
If you don't have perl yet then we have a binary packaged version for windows. Install Dwimperl.

`dwimmer_admin.pl --setup --password ADMIN_PASSWORD --email email-of-admin@company.com --root path/to/your/installation`

------------
Upgrade:

cpan Dwimmer

dwimmer_admin.pl --upgrade --password ADMIN_PASSWORD --root path/to/your/installation



==============
Sources:
JQuery http://jquery.com/
http://www.scriptbreaker.com/javascript/script/JQuery-Drop-down-panel-menu



CLEditor WYSIWYG HTML Editor v1.3.0
http://premiumsoftware.net/cleditor
Advanced Table Plug-in Version 1.0.0

=================

Feed collector:

```
perl -Ilib script/dwimmer_feed_admin.pl --store all.db --setup
```
```
perl -Ilib eg/import_from_old_feeds.pl  all.db  perl.db Perl
```
```
perl -Ilib script/dwimmer_feed_admin.pl --store all.db --config html_dir /home/gabor/tmp/feedtest --site Perl
```
```
perl -Ilib script/dwimmer_feed_collector.pl --store all.db --sendmail --collect;
```

CM collector: (Theoretically we could have both the Perl and CM site in the same database, but it is already big and we might want to separate the two servers.)

```
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --setup
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --addsite CM
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --config admin_name "Gabor Szabo"  --site CM
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --config admin_email "..."  --site CM

perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --config url http://feed.code-maven.com/  --site CM
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --config title "Code Maven feed collector"  --site CM
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --config subject_tt "CM feed: [% title %]"  --site CM
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --config name "CM"  --site CM
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --config html_dir /home/gabor/tmp/code_maven --site CM
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --config from ... --site CM
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --config description "Technology feeds" --site CM
```

to verify:

```
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --listconfig --site CM | less
```

Add RSS feeds:

```
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --site CM --add
URL:
Feed (Atom or RSS) : 
Title :
Twitter :
Comment :
```

List RSS feeds:
```
perl -Ilib script/dwimmer_feed_admin.pl --store ~/code_maven_feed.db --site CM --listsource
```

```
mkdir ~/tmp/code_maven
```

Configure web server to point to the new feed directory

