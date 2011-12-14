git log --decorate=full --simplify-by-decoration --pretty=oneline HEAD |
grep '(' |
sed -r -e 's#^[^\(]*\(([^\)]*)\).*$#\1#' -e 's#,#\n#g' -e 's# ##g' |
grep 'tag:release-'| sed s#tag:release-##