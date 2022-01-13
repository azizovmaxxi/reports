module.exports = function getRole(user){
  return user.roles.map(role => role.Name.toLowerCase()).find(role => {
    return role === 'republic' || role === 'oblast' || role === 'region' || role === 'lpu'
  });
}