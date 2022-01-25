/**
 * Checks for cross references between specs and feature files. Specifically, it lists out:
 * - Which acceptance criteria are referred to in a feature file
 * - Which acceptance criteria are not referred to in any feature file
 *
 * This script is pretty ugly. Sorry.
 */
const fs = require('fs')
const { protocolSpecificationsPath, validSpecificationPrefix, validAcceptanceCriteriaCode, featurePath } = require('./lib')

// Step 1: Gather all the initial details
const specFiles = new Map()
fs.readdirSync(protocolSpecificationsPath).forEach(file => {
  if (file.match(/md|ipynb$/) && file !== 'README.md') {
    const content = fs.readFileSync(`${protocolSpecificationsPath}${file}`, 'ascii')
    const codeStart = file.match(validSpecificationPrefix)

    // Gather the AC codes in this file
    const regex = new RegExp(`${codeStart[0]}-([0-9]{3})`, 'g')
    const labelledAcceptanceCriteria = content.match(regex)
    let criteria = []

    if (labelledAcceptanceCriteria !== null) {
      // Dedupe labelled acceptance criteria
      criteria = [...new Set(labelledAcceptanceCriteria)]
    }

    specFiles.set(file, {
      name: file,
      code: codeStart[0],
      criteria
    })
  }
})

// Step 2: Gather all the features
const linksInFeatures = new Map()
fs.readdirSync(featurePath).forEach(file => {
  if (file.match(/feature/) && file !== 'README.md') {
    const content = fs.readFileSync(`${featurePath}${file}`, 'ascii')

    const codesInFeature = content.match(validAcceptanceCriteriaCode)

    if (codesInFeature !== null) {
      codesInFeature.forEach(acCode => {
        if (linksInFeatures.has(acCode)) {
          const referrers = linksInFeatures.get(acCode)
          referrers.push(file)

          linksInFeatures.set(acCode, [...new Set(referrers)])
        } else {
          linksInFeatures.set(acCode, [file])
        }
      })
    }
  }
})

// Step 3: Output the data
specFiles.forEach((value, key) => {
  console.group(key)
  console.log(`Criteria:      ${value.criteria.length}`)

  // Tally Criteria
  if (value.criteria && value.criteria.length > 0) {
    const criteriaWithRefs = []
    let refOutput = ''
    value.criteria.forEach(c => {
      const linksForAC = linksInFeatures.get(c)
      if (linksForAC) {
        refOutput += `${c}:  ${linksForAC.length} (${linksForAC.toString()})\r\n`
        criteriaWithRefs.push(c)
      }
    })

    if (refOutput.length > 0) {
      console.group('Feature references')
      console.log(refOutput)
      console.groupEnd('Feature references')
    }

    if (criteriaWithRefs.length !== value.criteria.length) {
      console.group('Unreferenced ACs')
      value.criteria.forEach(v => {
        if (!criteriaWithRefs.includes(v)) {
          console.log(v)
        }
      })
      console.groupEnd('Feature references')
    }
  }
  console.groupEnd(key)
})

console.log('\r\n\r\n')
