const terIsAvailable = require('./terIsAvailable')
const ifCond = require('./ifCond')
const dateFormat = require('./dateFormat')
const incremented = require('./incremented')

module.exports = {
  ...terIsAvailable,
  ...ifCond,
  ...dateFormat,
  ...incremented
}