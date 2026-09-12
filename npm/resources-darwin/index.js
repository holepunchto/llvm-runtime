require.asset = require('require-asset')

// Resolving the directory rather than a file inside it is what marks the
// whole package, which is the clang resource directory, as an asset.
module.exports = require.asset('./', __filename)
