const os = require('os')

module.exports = function resourceDir(opts) {
  if (!opts) opts = {}

  const { platform = os.platform() } = opts

  let mod
  try {
    mod = require(`llvm-runtime-resources-${platform}`)
  } catch (err) {
    if (err.code === 'MODULE_NOT_FOUND') {
      throw new Error(`No compiler runtime libraries found for platform '${platform}'`)
    } else {
      throw err
    }
  }

  return mod
}
