const { DataTypes, Model } = require("sequelize");
const sequelize = require("./sequalize");

class Role extends Model {}

Role.init({
  id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    primaryKey: true
  },
  Name: {
    type: DataTypes.STRING,
    allowNull: false,
  }
}, {
  sequelize,
  modelName: "Role",
  tableName: "AspNetRoles",
  timestamps: false
});

module.exports = Role;