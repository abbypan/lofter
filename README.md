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

perl lofter.pl -w 'chuweizhiyu' -b '时之足'

从第3章开始下载

perl lofter.pl -w 'chuweizhiyu' -b '时之足' -i 3

下载第3~5章

perl lofter.pl -w 'chuweizhiyu' -b '时之足' -i 3-5

![lofter.png](lofter.png)
