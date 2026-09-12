require.asset = require('require-asset')

exports['ld.lld'] = require.asset('./bin/ld.lld.exe', __filename)
exports['ld64.lld'] = require.asset('./bin/ld64.lld.exe', __filename)
exports['lld'] = require.asset('./bin/lld.exe', __filename)
exports['lld-link'] = require.asset('./bin/lld-link.exe', __filename)
exports['wasm-ld'] = require.asset('./bin/wasm-ld.exe', __filename)
