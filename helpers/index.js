const addresses = require('./addresses')
const BN = require('bn.js')

const rulings = {
  REFUSED: new BN(2),
  AGAINST_ACTION: new BN(3),
  FOR_ACTION: new BN(4)
}

module.exports = { addresses, rulings }
