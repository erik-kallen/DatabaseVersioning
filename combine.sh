export DIR=sql

x=$(
git log --decorate=full --simplify-by-decoration --pretty=oneline HEAD | # The log
grep '(' |                                                               # Only include entries with names
sed -r -e 's#^[^\(]*\(([^\)]*)\).*$#\1#' -e 's#,#\n#g' -e 's# ##g' |     # Select only the names, one line per name, delete spaces
grep 'tag:release-' |                                                    # Only release tags
sed 's#tag:##' |                                                         # Remove the tag: prefix
sed 's#^\(.*\)$#\1\n\1#g' |                                              # Duplicate the tags
sed '1iHEAD' |                                                           # Insert HEAD as the first line.
sed "\$s/\$/\n$(git log --reverse --pretty=format:%H | head -n 1)/" |    # Add the hash of the first commit to the end.
sed '1!G;h;$!d' |                                                        # Reverse to get oldest commits first
xargs -l2 |                                                              # Combine the lines in pairs. This means that each pair is of the form "old new"
sed -r 's#^(.+)[[:space:]](.+)$#\1:\2#'
)

first=1
for line in $x
do
	diffcmd=$(echo $line | sed -r "s#(.+):(.+)#git diff \1 \2 --name-status -- $DIR"#) # Generate a git diff command that returns the changes between the old and the new revision
	filelist=$($diffcmd |                                # Read the diff
	           grep '^A' |                               # Find all adds
	           sed -r s/^A[[:space:]]+//g |              # Remove the A[space] in the beginning of all lines.
	           grep "^$DIR/seq.*\.sql" |                 # Only ignore files with the name seqNNNN.sql
	           sort |                                    # Sort the files
	           xargs
	          )
	
	if [ "$filelist" ]
	then
		if [ "$first" = "0" ]
		then
			echo Something
			echo $line | sed -r "s#(.+):(.+)#<<< \1 >>>#"
		fi
		first=0
	fi

	for filename in $filelist
	do
		cat $filename
		echo GO
	done
done
