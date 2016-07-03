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

my ( $writer, $book) = @ARGV;

$writer = decode( locale => $writer );
$book   = decode( locale => $book );
unless ( defined $writer and defined $book ) {
    print "example:
    perl lofter.pl 'chuweizhiyu' '时之足'
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

    my $post_r = $xs->{parser}->get_tiezi_ref($url,
        parse_info => sub { { writer=>$writer, book=>$book, title=>$book } },
        parse_content => sub {
            my ($h) = @_;
            my $r = scraper {
                process '//h2//a',
                'chapter[]' => {
                    title => 'TEXT',
                    url   => '@href'
                };
                result 'chapter';
            };
            my $chap_r = $r->scrape($h);
            return unless ( $chap_r and @$chap_r );
            my @chap_tidy = grep { $_->{title}=~/$book/
                and $_->{url}=~m#/post/# } @$chap_r;
            return \@chap_tidy;
        }, 
        #min_page_num=>2, 
        #max_page_num => 3, 
        #stop_iter=>sub {
        #my ($info, $data_list, $i, %o) = @_;
        #return 1 if($i>4);
        #},
        next_url => sub {
            my ($start_u, $i, $h) = @_;
            return "$start_u&page=$i";
        }, 
        deal_content_url => sub {
            my ($h) = @_;
            my $r = scraper {
                process '//div[starts-with(@class,"m-post ")]', 'content' => 'HTML';
                process '//div[@class="txtcont"]', 'cont1' => 'HTML';
                process '//div[@class="content"]', 'cont2' => 'HTML';
            };
            my $res=$r->scrape($h);
            return $res->{content} || $res->{cont1} || $res->{cont2};
        }, 
        reverse_content_list => 1, 
    );

    if ( $opt->{txt} ) {
        $xs->{packer}->main(
            #\%book_data,
            $post_r, 
            output   => $opt->{txt},
            with_toc => 0
        );
        return $opt->{txt};
    }

    my $d = '';
    $xs->{packer}->main(
        $post_r, 
        output   => \$d,
        with_toc => 0
    );
    $d =~ s/\n/\r\n/sg;
    $post_r->{data} = $d;
    return $post_r, 
}
