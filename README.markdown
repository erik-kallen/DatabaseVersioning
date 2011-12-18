Often, upgrading software means modifying table structure, often with default values in the new columns based on the content of the old columns. Sometimes you want to merge tables, sometimes you want to split them. IOW, in my experience you often need to keep track of which scripts to run and which ones have already been run.

The idea is that all data modification operations happen in files called sql/seqNNNN.sql. These files are intended to be run in order, and you have to make sure that every script is run exactly once. At various points you have releases, at which point you create tags release-X (where X is the release number). Once you have made a release, the seqNNNN.sql files inside that release must not change, if there is an error in them you have to create a compensation script with a higher sequence number.

All these files will be concatenated into one large script looking like

    Content of script 1
	With many lines
	CREATE TABLE...
	GO
	Content of script 2
	With many lines
	CREATE TABLE...
	GO
	<<<--- release-1.0.0 --->>>
	Content of script 3
	With many lines
	CREATE TABLE...
	GO
	<<<--- release-1.1.0 --->>>
	<<<--- release-1.2.0 --->>>
	Content of script 4
	With many lines
	CREATE TABLE...
	GO
	<<<--- release-1.3.0 --->>>
	Content of script 5
	With many lines
	CREATE TABLE...
	
IE, the content of the combined file is the concatenation of all the seqNNNN.sql files, with a GO between each file (for MSSQLServer, for Oracle it would have been /, etc.) Also, the point of each release is inside the script, so your upgrade tool would perform the following steps:

 1. Determine the current version
 2. Read lines in the file until it finds a line with the content <<<--- release-CURRENT_VERSION --->>>
 3. Strip all later lines of the format <<<--- release-X --->>>
 4. Run the resulting script.
 5. Update the current version.
 
This repo is my attempt to use Git to help with this workflow. It contains the following parts:

 - A combine.sh script that generates the combined script based on the content and history of the sql directory.
 - A pre-commit hook (copy to .git/hooks) that prevents modification to any seqNNNN.sql file that is part of a release.

You might (debatable) also want to prevent automatic merge of the seqNNNN.sql files. To do this, use the supplied .gitattributes file and run the following commands to make it work:
 
    git config merge.nomerge.name "Strategy that prevents merge of the files"
	config merge.nomerge.driver "echo 'Cannot merge this file'; exit 1"
