module.exports = {
  protocolSpecificationsPath: './protocol/',
  featurePath: './qa-scenarios/',
  validSpecificationFilename: /^([0-9]{4})-([A-Z]{4})-([a-z_]+)/,
  validSpecificationPrefix: /^([0-9]{4}-[A-Z]{4})/,
  validAcceptanceCriteriaCode: /([0-9]{4}-[A-Z]{4})-([0-9]{3})/g
}
