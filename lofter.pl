#!/usr/bin/perl 

use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Getopt::Std;

use Web::Scraper;
use Novel::Robot;
use Data::Dumper;

$| = 1;
binmode( STDIN,  ":encoding(console_in)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );

my %opt;
getopt( 'wbi', \%opt );
my $writer = decode( locale => $opt{w} );
my $book   = decode( locale => $opt{b} );
$opt{i} ||= '';
unless ( defined $writer and defined $book ) {
  print "example:
    perl lofter.pl -w 'chuweizhiyu' -b '时之足' -i 3
    \n";
  exit;
}

my $output = encode( locale => "$writer-$book.txt" );
my $bk = get_lofter_book( { writer => $writer, book => $book, txt => $output, i => $opt{i} } );

sub get_lofter_book {
    my ( $opt ) = @_;
    my $writer  = $opt->{writer};
    my $book    = $opt->{book};

    my ( $min, $max ) = split '-', $opt->{i};

    my $BASE_URL = "http://$writer.lofter.com";
    $b = uc( unpack( "H*", encode( "utf8", $book ) ) );
    $b =~ s/(..)/%$1/g;
    my $url = "$BASE_URL/search/?q=$b";

    #print $url, "\n";

    my $xs = Novel::Robot->new( site => 'txt', type => 'txt', verbose => 1 );

    my $post_r = $xs->{parser}->get_tiezi_ref(
        $url,
        verbose      => 1,
        min_item_num => $min,
        max_item_num => $max,
        info_sub     => sub { { writer => $writer, book => $book, title => $book } },
        content_sub  => sub {
            my ( $h ) = @_;
            my $r = scraper {
                process '//ul[@class="m-list"]//li',
                'artical[]' => { url => 'HTML', };
                process '//h2//a',
                'chapter[]' => {
                    title => 'TEXT',
                    url   => '@href'
                };
                process '//a[@class="title"]',
                'chap[]' => {
                    title => 'TEXT',
                    url   => '@href'
                };
            };
            my $res_r = $r->scrape( $h );
            my $chap_r =
            ( $res_r->{artical} and @{ $res_r->{artical} } ) ? $res_r->{artical}
            : ( $res_r->{chapter} and @{ $res_r->{chapter} } ) ? $res_r->{chapter}
            : ( $res_r->{chap}    and @{ $res_r->{chap} } )    ? $res_r->{chap}
            :                                                    undef;
            return unless ( $chap_r and @$chap_r );
            if ( $res_r->{artical} ) {
                ( $_->{title} ) = $_->{url} =~ m#<strong>(.+?)</strong>#s for @$chap_r;
                ( $_->{url} )   = $_->{url} =~ m#<a href="([^"]+)">#s     for @$chap_r;
            }
            my @chap_t = grep { $_->{url} =~ m#/post/# } @$chap_r;

            return unless ( @chap_t );
            my @chap_tidy = grep { $_->{title} =~ /$book/i } @chap_t;
            return \@chap_tidy;
        },
        stop_sub => sub { return; },

        #min_page_num=>2,
        #max_page_num => 3,
        #stop_iter=>sub {
        #my ($info, $data_list, $i, %o) = @_;
        #return 1 if($i>4);
        #},
        next_url_sub => sub {
            my ( $start_u, $i, $h ) = @_;

            #print "$start_u&page=$i\n";
            return "$start_u&page=$i";
        },
        item_sub => sub {
            my ( $r ) = @_;

            #print $r->{url},"\n";
            my $c = $xs->{browser}->request_url( $r->{url} );
            my $s = scraper {
                process '//div[starts-with(@class,"m-post ")]',
                'content' => 'HTML';
                process '//div[@class="txtcont"]',  'cont1' => 'HTML';
                process '//div[@class="content"]',  'cont2' => 'HTML';
                process '//div[@class="postdesc"]', 'cont3' => 'HTML';
                process '//div[@class="article"]',  'cont4' => 'HTML';
            };
            my $res = $s->scrape( \$c );
            $r->{content} = $res->{content} || $res->{cont1} || $res->{cont2} || $res->{cont3} || $res->{cont4};
            return $r;
        },
        reverse_content_list => 1,
    );

    return unless ( $post_r->{floor_list}[-1]{content} );
    print "last_chapter_id : $post_r->{floor_list}[-1]{id}\n";

    if ( $opt->{txt} ) {
        $xs->{packer}->main(

            #\%book_data,
            $post_r,
            output   => $opt->{txt},
            with_toc => 0
        );
        return $post_r;
    }

    my $d = '';
    $xs->{packer}->main(
        $post_r,
        output   => \$d,
        with_toc => 0
    );
    $d =~ s/\n/\r\n/sg;
    $post_r->{data} = $d;
    return $post_r,;
} ## end sub get_lofter_book
