To set up the nomerge strategy run the following commands:
    git config merge.nomerge.name "Strategy that prevents merge of the files"
	config merge.nomerge.driver "echo 'Cannot merge this file'; exit 1"