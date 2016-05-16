#!/usr/bin/perl 

use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;

use Web::Scraper;
use Novel::Robot;
use Data::Dumper;

$| = 1;
binmode( STDIN,  ":encoding(console_in)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );

my ( $writer, $book, $pg_max_n ) = @ARGV;

$writer = decode( locale => $writer );
$book   = decode( locale => $book );
unless ( defined $writer and defined $book ) {
    print "example:
    perl lofter.pl 'chuweizhiyu' '时之足' 30
    \n";
    exit;
}

my $BASE_URL = "http://$writer.lofter.com";
$b = uc( unpack( "H*", encode( "utf8", $book ) ) );
$b =~ s/(..)/%$1/g;
my $url = "$BASE_URL/search/?q=$b";
print "url : $url\n";

my $xs = Novel::Robot->new( site => 'txt', type => 'txt' );
my @floor;
my $i = 1;
while (1) {
    last if ( $pg_max_n and $i > $pg_max_n );
    print "extract chapter url : $url\n";
    my $h = $xs->{browser}->request_url($url);
    my $r = scraper {
        process '//h2[@class="ttl"]//a',
          'chapter[]' => {
            title => 'TEXT',
            url   => '@href'
          };
        process_first '//a[@class="next "]',
          'next' => {
            title => 'TEXT',
            url   => '@href'
          };
    };
    my $chap_r = $r->scrape($h);
    push @floor, @{ $chap_r->{chapter} };
    last unless ( $chap_r->{next} and $chap_r->{next}{url} );
    $url = "$BASE_URL$chap_r->{next}{url}";
    $i++;
}
@floor = reverse @floor;
$xs->{parser}->update_url_list( \@floor, $BASE_URL );

for my $x (@floor) {
    my $u = $x->{url};
    print "download chapter : $u\n";
    my $h = $xs->{browser}->request_url($u);
    my $r = scraper {
        process '//div[@class="txtcont"]', 'content' => 'HTML';
        result 'content';
    };
    $x->{content} = $r->scrape($h);
}

my %book_data = (
    writer     => $writer,
    book       => $book,
    floor_list => \@floor,
    url        => $url,
);

$xs->{packer}->main(
    \%book_data,
    output   => encode( locale => "$writer-$book.txt" ),
    with_toc => 0
);
