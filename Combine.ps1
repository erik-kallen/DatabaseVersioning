# The directory we are monitoring (relative to the root of the repository)
$dir="sql"
# String to find in the tags of interest
$tagpattern="release-.*"
# Separator to add after each added file
$fileseparator="GO"
# Files of interest
$filepattern="seq.*\.sql"
# Separator to add between the concatenated files for each tag. \1 denotes the revision.
$versionseparator="----<<<< \1 >>>>---- f10048cf6c444db4b297b78d06a06043"

$pairs =
% { git log --reverse --pretty=format:%H | Select-Object -First 1 } {                   # Start with the oldest commit reachable from where we are
   (git log --reverse --decorate=full --simplify-by-decoration --pretty=oneline HEAD |  # Append items from the log
    Select-String '\(' |                                                                #    Only include entries with names
    % { ($_ -replace "^[^(]*\(([^)]*)\).*$","`$1" -replace " ", "").Split(',') } |      #    Select only the names, one line per name, delete spaces
    Select-String "tag:$tagpattern" |                                                   #    Only tags of interest
    % { $_ -replace "tag:", "" } |                                                      #    Remove the tag: prefix
    % { $_; $_ }) }  {                                                                  #    Duplicate the tags
   "HEAD" } |                                                                           # End with the current head
% { if ($x -ne $null) { @{ "Old" = $x; "New" = $_ }; $x = $null } else { $x = $_ } }    # Combine the items into (old, new) pairs

$rootdir = "$(git rev-parse --show-toplevel)"

$pairs |
%	-Begin { $first = 1 } {
	$filelist = @(
		Invoke-Expression "git diff $($_.Old) $($_.New) --name-status -- $rootdir\$dir" |  # Use git diff to return the changes between the old and the new revision
		Select-String "^A" |                                                               # Find all adds
		% { $_ -replace "^A[ \t]+", "" } |                                                 # Remove the A[space] in the beginning of all lines.
		Select-String "^$dir/$filepattern$" |                                              # Include only the files we care about
		Sort-Object                                                                        # Sort the files by name
	)

	if ($filelist.Length -ne 0) {
		if ($first -eq 0) {
			$versionseparator -replace "\\1", $_.Old
		}
		$first = 0

		$filelist | % { Get-Content "$rootdir\$_"; echo $fileseparator }
	}
}
