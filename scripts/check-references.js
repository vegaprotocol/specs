/**
 * Checks for cross references between specs and feature files. Specifically, it lists out:
 * - Which acceptance criteria are referred to in a feature file
 * - Which acceptance criteria are not referred to in any feature file
 * - Which specs are referenced by another spec
 *
 * This script is pretty ugly. Sorry.
 */
const fs = require('fs')
const { protocolSpecificationsPath, validSpecificationPrefix, validAcceptanceCriteriaCode, featurePath } = require('./lib')

// Outputs acceptance criteria count if it's acceptable
const specFiles = new Map()
const linksInSpecs = new Map()
const linksInFeatures = new Map()

// Step 1: Gather all the initial details
fs.readdirSync(protocolSpecificationsPath).forEach(file => {
  if (file.match(/md|ipynb$/) && file !== 'README.md') {
    const content = fs.readFileSync(`${protocolSpecificationsPath}${file}`, 'ascii')
    const codeStart = file.match(validSpecificationPrefix)

    let criteria = []
    let references = []

    const regex = new RegExp(`${codeStart[0]}-([0-9]{3})`, 'g')
    const labelledAcceptanceCriteria = content.match(regex)

    if (labelledAcceptanceCriteria !== null) {
      // Dedupe labelled acceptance criteria
      criteria = [...new Set(labelledAcceptanceCriteria)]
    }

    const markdownLinksToSpecs = content.match(/]\(([^)]*)\)/g) 

    if (markdownLinksToSpecs) {
      // A mess. Cleaning up the link targets until they match the filenames
      references = markdownLinksToSpecs.map(c => {
        const name = c.substring(2, c.length - 1).replace('./', '')

        if (linksInSpecs.has(file)) {
          const referrers = linksInSpecs.get(file)
          referrers.push(file)

          linksInSpecs.set(file, [...new Set(referrers)])
        } else {
          linksInSpecs.set(file, [name])
        }

        return name
      })
    }

    specFiles.set(file, {
      name: file,
      code: codeStart[0],
      criteria,
      references
    })
  }
})

// Step 2: Gather all the features
fs.readdirSync(featurePath).forEach(file => {
  if (file.match(/feature/) && file !== 'README.md') {
    const content = fs.readFileSync(`${featurePath}${file}`, 'ascii')

    const matchedContent = content.match(validAcceptanceCriteriaCode)

    if (matchedContent !== null) {
      matchedContent.forEach(acCode => {
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

specFiles.forEach((value, key) => {
  let refs = []
  if (linksInSpecs.has(key)) {
    refs = linksInSpecs.get(key)
  }

  console.group(key)
  console.log(`Criteria:      ${value.criteria.length}`)
  console.log(`Referenced by: ${refs.length}`)

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
