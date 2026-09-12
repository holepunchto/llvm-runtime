require.asset = require('require-asset')

exports['ld.lld'] = require.asset('./bin/ld.lld', __filename)
exports['ld64.lld'] = require.asset('./bin/ld64.lld', __filename)
exports['lld'] = require.asset('./bin/lld', __filename)
exports['lld-link'] = require.asset('./bin/lld-link', __filename)
exports['wasm-ld'] = require.asset('./bin/wasm-ld', __filename)
