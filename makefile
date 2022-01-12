names: protocol/*.md
	find protocol/*.md protocol/*.ipynb ! '(' -name 'README.md' ')' | grep -vE '[0-9]{4}-[A-Z]{4}-[a-z][a-z_]*\.?(md|ipynb)' && echo 'Incorrect file names' || echo 'All protocol specs named correctly'
