const fs = require('fs')
const path = require('path')
const childProcess = require('child_process')
const runtime = require('..')
const resourceDir = require('./resource-dir')

// The drivers look for the builtin headers, the compiler runtime libraries and
// the linker relative to their own directory, and each of the three ships as a
// separate package. The installed drivers read the same answers from a
// configuration file, which resolving by package name gets right in a layout
// npm did not lay out, such as this repository's own workspace.
const drivers = new Set(['clang', 'clang++', 'clang-cl', 'clang-cpp'])

module.exports = function spawn(referrer, opts) {
  if (typeof referrer === 'object' && referrer !== null) {
    opts = referrer
    referrer = 'clang'
  } else if (typeof referrer !== 'string') {
    referrer = 'clang'
  }

  if (!opts) opts = {}

  let { args = typeof Bare !== 'undefined' ? Bare.argv.slice(2) : process.argv.slice(2) } = opts

  const bin = runtime(referrer, opts)

  if (drivers.has(path.basename(referrer))) {
    args = [`-B${path.dirname(runtime('ld.lld', opts))}`, ...args]

    if (!hasResourceDir(args)) {
      args = [`-resource-dir=${resourceDir(opts)}`, ...args]
    }
  }

  try {
    fs.accessSync(bin, fs.constants.X_OK)
  } catch {
    fs.chmodSync(bin, 0o755)
  }

  return childProcess.spawn(bin, args, opts)
}

function hasResourceDir(args) {
  return args.some((arg) => arg === '-resource-dir' || arg.startsWith('-resource-dir='))
}
