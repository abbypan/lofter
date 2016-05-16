# lofter

download post from lofter.com  ,  convert to  txt

下载lofter.com的帖子，自动转换成txt电子书


## 安装

安装 perl

cpan App::cpanminus

cpanm Encode::Locale

cpanm Web::Scraper

cpanm Novel::Robot

## 例子

全部下载

perl lofter.pl 'chuweizhiyu' '时之足'

只下载前3页

perl lofter.pl 'chuweizhiyu' '时之足' 3

![lofter.png](lofter.png)
