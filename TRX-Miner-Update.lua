local data = require("data")
if fs.exists("TRX-Miner") == true then shell.run("delete TRX-Miner") end
if fs.exists("trx_miner_conf") then
	local options = data.get("options","trx_miner_conf")
	data.set("options",options,"trx-miner.conf")
	shell.run("delete trx_miner_conf")
end
if fs.exists("trx-miner-version") == true then
	local version = data.get("version","trx-miner-version")
	data.set("version",version,"trx-miner.version")
	shell.run("delete trx-miner-version")
end
if fs.exists("log.lua") == true then shell.run("delete log.lua") end
shell.run("wget https://raw.githubusercontent.com/Terandox-The-Pineapple/TRX-Miner/main/TRX-Miner.lua TRX-Miner")
shell.run("Clear")
if fs.exists("trx-miner-version-check") then shell.run("delete trx-miner-version-check") end
if fs.exists("TRX-Miner-Update") then shell.run("delete TRX-Miner-Update") end
shell.run("TRX-Miner")
return 0