const os = require('os')
const path = require('path')

const components = ['clang', 'lld']

module.exports = function runtime(referrer, opts) {
  if (typeof referrer === 'object' && referrer !== null) {
    opts = referrer
    referrer = 'clang'
  } else if (typeof referrer !== 'string') {
    referrer = 'clang'
  }

  if (!opts) opts = {}

  const { platform = os.platform(), arch = os.arch() } = opts

  const filename = path.basename(referrer)

  let found = false

  for (const component of components) {
    let mod
    try {
      mod = require(`llvm-runtime-${component}-${platform}-${arch}`)
    } catch (err) {
      if (err.code === 'MODULE_NOT_FOUND') {
        continue
      } else {
        throw err
      }
    }

    found = true

    if (filename in mod) return mod[filename]
  }

  if (found === false) {
    throw new Error(`No binaries found for target '${platform}-${arch}'`)
  }

  throw new Error(`No binary found for target '${platform}-${arch}' for referrer '${referrer}'`)
}
