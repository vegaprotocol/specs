names:
	find protocol/*.md protocol/*.ipynb ! '(' -name 'README.md' ')' | grep -vE '[0-9]{4}-[A-Z]{4}-[a-z][a-z_]*\.?(md|ipynb)' && echo 'Incorrect file names' || echo 'All protocol specs named correctly'

show-duplicate-numbers:
	find protocol/*.md protocol/*.ipynb ! '(' -name 'README.md' ')' | grep -oE '[0-9]{4}*' | sort | uniq -dc

numbers:
	find protocol/*.md protocol/*.ipynb ! '(' -name 'README.md' ')' | grep -oE '[0-9]{4}*' | sort -uC && echo "All numbers are unique" || echo "Duplicate numbers"

acid:
	grep -nE '"[0-9]{4}-[[:upper:]]{4}-[0-9]{3}"' protocol/*.md
