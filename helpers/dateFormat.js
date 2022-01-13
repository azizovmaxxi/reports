const moment = require('moment')

module.exports = {
  dateFormat: function (date) {
    return moment(date).format('DD.MM.YYYY');
  }
}