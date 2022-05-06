local data = require("data")

local version = 1.21

if fs.exists("trx-miner-version") then data.set("version",version,"trx-miner-version-check")
elseif fs.exists("trx-miner.version") then data.set("version",version,"trx-miner.cversion") end