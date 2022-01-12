names: protocol/*.md
	find protocol/*.md ! '(' -name 'README.md' ')' | grep -vE '[0-9]{4}-[A-Z]{4}-[a-z_]*\.md' && echo 'Incorrect file names' || echo 'All protocol specs named correctly'
