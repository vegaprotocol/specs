all: names codes

names:
	node scripts/check-filenames.js

codes:
	node scripts/check-codes.js 	
