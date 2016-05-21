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

my $output = encode( locale => "$writer-$book.txt" );

get_lofter_book( { writer => $writer, book => $book, txt => $output } );

sub get_lofter_book {
    my ($opt)  = @_;
    my $writer = $opt->{writer};
    my $book   = $opt->{book};

    my $BASE_URL = "http://$writer.lofter.com";
    $b = uc( unpack( "H*", encode( "utf8", $book ) ) );
    $b =~ s/(..)/%$1/g;
    my $url = "$BASE_URL/search/?q=$b";

    my $xs = Novel::Robot->new( site => 'txt', type => 'txt' );
    my @floor;
    my $i = 1;
    my $u = $url;
    while (1) {
        last if ( $opt->{max_page_num} and $i > $opt->{max_page_num} );
        my $h = $xs->{browser}->request_url($u);
        my $r = scraper {
            process '//h2[@class="ttl"]//a',
              'chapter[]' => {
                title => 'TEXT',
                url   => '@href'
              };
            result 'chapter';
        };
        my $chap_r = $r->scrape($h);
        last unless ( $chap_r and @$chap_r );
        push @floor, @$chap_r;
        $i++;
        $u = "$url&page=$i";
    }
    @floor = reverse @floor;
    $xs->{parser}->update_url_list( \@floor, $BASE_URL );

    for my $x (@floor) {
        my $u = $x->{url};
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

    if ( $opt->{txt} ) {
        $xs->{packer}->main(
            \%book_data,
            output   => $opt->{txt},
            with_toc => 0
        );
        return $opt->{txt};
    }

    my $d = '';
    $xs->{packer}->main(
        \%book_data,
        output   => \$d,
        with_toc => 0
    );
    $d =~ s/\n/\r\n/sg;
    $book_data{data} = $d;
    return \%book_data;
}
