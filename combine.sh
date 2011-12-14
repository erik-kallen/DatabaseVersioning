git log --decorate=full --simplify-by-decoration --pretty=oneline HEAD |   # The log
grep '(' |                                                                 # Only include entries with names
sed -r -e 's#^[^\(]*\(([^\)]*)\).*$#\1#' -e 's#,#\n#g' -e 's# ##g' |       # Select only the names, one line per name, delete spaces
grep 'tag:release-' |                                                      # Only release tags
sed 's#tag:##' |                                                           # Remove the tag: prefix
sed 's#^\(.*\)$#\1\n\1#g' |                                                # Duplicate the tags
sed '1iHEAD' |                                                             # Insert HEAD as the first line.
sed "\$s/\$/\n`git log --reverse --pretty=format:%H | head -n 1`/" |       # Add the hash of the first commit to the end.
sed '1!G;h;$!d' |                                                          # Reverse to get oldest commits first
xargs -l2                                                                  # Combine the lines in pairs. This means that each pair is of the form 