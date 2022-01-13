const { DataTypes, Model } = require("sequelize");
const sequelize = require("./sequalize");
const Role      = require('./role.js');

class User extends Model {}

User.init({
  id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    primaryKey: true
  },
  UserName: {
    type: DataTypes.STRING,
    allowNull: false
  },
  PasswordHash: {
    type: DataTypes.STRING,
    allowNull: false
  },
  GsvId: {
    type: DataTypes.INTEGER,
    allowNull: false
  }
}, {
  sequelize,
  modelName: "User",
  tableName: "AspNetUsers",
  timestamps: false
});

User.belongsToMany(Role, {as: "roles", through: "AspNetUserRoles", foreignKey: 'UserId'});

module.exports = User;