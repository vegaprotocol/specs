module.exports = {
  protocolSpecificationsPath: './protocol/',
  nonProtocolSpecificationsPath: './non-protocol-specs/',
  featurePath: './qa-scenarios/',
  validSpecificationFilename: /^([0-9]{4})(-NP)?-([A-Z]{4})-([a-z_]+)/,
  validSpecificationPrefix: /^([0-9]{4}(-NP)?-[A-Z]{4})/,
  validAcceptanceCriteriaCode: /([0-9]{4}(-NP)?-[A-Z]{4})-([0-9]{3})/g
}

