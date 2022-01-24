/**
 * Check all markdown files in the protocol folder for Acceptance Criteria anchors and links.
 * For each acceptance criteria, we want a self-linking anchor tag, in a format that will be
 * rendered in GitHub's readme panel. 
 * 
 * An acceptance criteria ID is based off:
 * 1. The sequence number of the specification file
 * 2. The 4 character string ID of the specification file
 * 3. The count of the criteria
 * 
 * So in `0001-EXMP-example-specification.md` there should be the following code:
 *   `<a name="0001-EXMP-001" href="#0001-EXMP-001">0001-EXMP-001</a>`
 * for each specific criteria that might need to be linked from a test.
 * 
 * This script uses a bunch of basic assumptions to point to files that:
 * 1. Have no acceptance criteria at all, which is probably not good
 * 2. Have less than minimumAcceptableCount criteria, which should be addressed
 * 3. Looks like it doesn't have the anchor tag as above in it
 * 
 * Number 3 uses a basic regex to check that there are 3 instances of each ID, an assumption
 * that will almost certainly break with internal linking over time. But it works for now.
 * 
 * This script can be replaced by a script in any language, as long as it helps point to 
 * files that don't look right as per the above. It's not elegant, but it gets the job done.
 */
const fs = require("fs");

/**
 * Generator to chunk array by defined size, defaulting to 3
 * 
 * @param {*} arr 
 * @param {number} n 
 */
function* chunks(arr, n = 3) {
  for (let i = 0; i < arr.length; i += n) {
    yield arr.slice(i, i + n);
  }
}

const path = "./protocol/";

// Outputs acceptance criteria count if it's acceptable
const isVerbose = false;

// How many acceptance criteria are enough?
let minimumAcceptableCount = 1;
// The number of files that appear to have 0 acceptance criteria
let countEmptyFiles = 0;
// The number of files that appear to have errors
let countErrorFiles = 0;
// The number of files that appear to have enough detail
let countAcceptableFiles = 0;
// Total acceptance criteria across all files
let countAcceptanceCriteria = 0;

fs.readdirSync(path).forEach(file => {
  if (file.match(/md|ipynb$/) && file !== 'README.md') {
    let content = fs.readFileSync(`${path}${file}`, `ascii`);
    let codeStart = file.match(/^([0-9]{4}-[A-Z]{4})/);

    const regex = new RegExp(`${codeStart[0]}-([0-9]{3})`, 'g')
    const matchedContent = content.match(regex);

    if (matchedContent === null){
      // There were no matches for the AC prefix, so this file probably needs attention
      countEmptyFiles++;
      console.group(file);
      console.error(`no acceptance criteria`);
    } else {
      // Acceptance code links are self referential, and have a name property, which makes
      // 3 instances of each code. So a basic check for this is to split the matches in to 
      // arrays of 3
      const chunkedMatches = [...chunks(matchedContent)]

      // Then get a count of unique elements in each of those array. They should all be one
      const totalAcceptanceCriteria = chunkedMatches.map(c => [...new Set(c)].length);

      // If all of the arrays aren't 1, there's probably a mistake. Output all chunks to 
      // point to where the error is
      const unbalancedChunks = totalAcceptanceCriteria.filter(i => i !== 1);

      countAcceptanceCriteria += totalAcceptanceCriteria.length;

      if (unbalancedChunks.length > 0) {
        // Something is wrong, dump out the array as a starting point for working out what
        countErrorFiles++;
        console.group(file);
        console.log(`${totalAcceptanceCriteria.length} acceptance criteria`);
        console.error(`Found something odd:`);
        console.dir(chunkedMatches);
      } else {
        // The files are *valid*, at least. But do they have enough ACs?
        if (totalAcceptanceCriteria.length >= minimumAcceptableCount) {
          countAcceptableFiles++;
          if (isVerbose) {
            console.log(`${totalAcceptanceCriteria.length} acceptance criteria`);
          }
        } else {
          countErrorFiles++;
          console.error(`${totalAcceptanceCriteria.length} acceptance criteria`);
       }
      }

    }
  
    console.groupEnd(file);
  }
});

console.log('\r\n--------------------------------------------------');
console.log(`Acceptable         ${countAcceptableFiles} (files with more than ${minimumAcceptableCount} ACs)`);
console.log(`Need work          ${countEmptyFiles}`);
console.log(`Files with errors  ${countErrorFiles}`);
console.log(`Total ACs          ${countAcceptanceCriteria}`);
console.log('\r\n\r\n');
