/**
 * Check all markdown files in the protocol folder are name appropriately
 *
 * An filename is based off:
 * 1. The sequence number of the specification file
 * 2. The 4 character string ID of the specification file
 *
 * This script can be replaced by a script in any language, as long as it helps point to
 * files that don't look right as per the above. It's not elegant, but it gets the job done.
 */
const fs = require('fs')
const { validSpecificationFilename, protocolSpecificationsPath, nonProtocolSpecificationsPath } = require('./lib')

// Configure the acc
const maxInvalidFilenames = 0

// Keeps track of seen sequence numbers so we can detect duplicates
const seenSequenceNumbers = { }; 
// Tally of filenames that pass all the checks
let countValidFilenames = 0
// Tally of filenames that fail any checks
let countInvalidFilenames = 0

function checkFolder(path) {
  seenSequenceNumbers[path] = []

  fs.readdirSync(path).forEach(file => {
    if (file.match(/md|ipynb$/) && file !== 'README.md') {
      const codeStart = file.match(validSpecificationFilename)

      // If the filename doesn't match, it's an error
      if (codeStart === null) {
        console.error(`Invalid filename: ${file}`)
        countInvalidFilenames++
      } else {
        // If the sequence number is 0000, it's incorrect
        if (codeStart[1] === '0000') {
          console.error(`Invalid sequence number 0000: ${file}`)
          countInvalidFilenames++
        } else {
          // If the sequence number is a duplicate, it's incorrect
          if (seenSequenceNumbers[path].indexOf(codeStart[1]) !== -1) {
            console.error(`Duplicate sequence number ${codeStart[1]}: ${file}`)
            countInvalidFilenames++
          } else {
            seenSequenceNumbers[path].push(codeStart[1])
          }
        }

        // There should be a human readable bit after the sequence/code
        if (!codeStart[3].length > 0) {
          console.error(`Duplicate sequence number ${codeStart[1]}: ${file}`)
          countInvalidFilenames++
        } else {
          countValidFilenames++
        }

        // Unnecessary check, but as we're here anyway - is the file empty?
        const content = fs.readFileSync(`${path}${file}`, 'ascii')
        if (content.length === 0) {
          console.error(`Empty file: ${file}`)
        }
      }
    }
  })

  // An acceptable error, output anyway: is there a missing sequence number?
  const missingSequenceNumbers = seenSequenceNumbers[path].filter((n, i) =>
    (i < seenSequenceNumbers[path].length - 1 && parseInt(seenSequenceNumbers[path][i + 1]) !== parseInt(n) + 1)
  ).map(n => parseInt(n) + 1)

  if (missingSequenceNumbers.length > 0) {
    console.info(`Missing sequence number: ${missingSequenceNumbers}`)
  }

}

checkFolder(protocolSpecificationsPath);
checkFolder(nonProtocolSpecificationsPath);

console.log('\r\n--------------------------------------------------')
console.log(`Correctly named    ${countValidFilenames}`)
console.log(`Errors             ${countInvalidFilenames}`)
console.log('\r\n\r\n')

if (countInvalidFilenames > maxInvalidFilenames) {
  process.exit(1)
}

process.exit(0)
