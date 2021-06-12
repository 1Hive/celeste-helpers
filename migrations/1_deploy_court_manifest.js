const fs = require('fs')

const Manifest = artifacts.require('ArbitratorManifest')
const ADDRESSES_SRC = './helpers/addresses.json'

module.exports = async (deployer, network) => {
  if (network === 'xdai') {
    const DISPUTE_MANAGER = '0xec7904e20b69f60966d6c6b9dc534355614dd922'
    await deployer.deploy(Manifest, DISPUTE_MANAGER)
  }
  const addresses = JSON.parse(fs.readFileSync(ADDRESSES_SRC, 'utf8'))
  const manifest = await Manifest.deployed()
  addresses[network].manifest = manifest.address
  fs.writeFileSync(ADDRESSES_SRC, JSON.stringify(addresses, null, 2))
}
