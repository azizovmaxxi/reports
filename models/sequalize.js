const Sequelize = require("sequelize");
const config = require("../config/config");

const sequelizeInit = new Sequelize(config.DB.CATALOG, config.DB.USER, config.DB.PASSWORD,
  {
    dialect: config.DB.DIALECT,
    host: config.DB.HOST,
    port: config.DB.PORT,
    pool: {
      max: config.DB.POOL.MAX,
      min: config.DB.POOL.MIN,
      acquire: config.DB.POOL.ACQUIRE,
      idle: config.DB.POOL.IDLE
    },
    define: {
      timestamps: false
    },
  }
);

module.exports = sequelizeInit;