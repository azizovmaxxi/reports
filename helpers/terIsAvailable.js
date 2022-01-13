module.exports = {
  terIsAvailable: function(user, targetField){
    //roles -- 'republic', 'oblast', 'region', 'lpu'

    const roles = user.roles.map(role => role.Name.toLowerCase());
    const oblastFields = ['ter3_id', 'ter4_id', 'lpu_id'];
    const regionFields = ['ter4_id', 'lpu_id'];
    const lpuFields    = ['lpu_id'];

    if(roles.includes('republic')){ return true }
    if(roles.includes('oblast') && oblastFields.includes(targetField)){ return true }
    if(roles.includes('region') && regionFields.includes(targetField)){ return true }
    if(roles.includes('lpu') && lpuFields.includes(targetField)){ return true }
    return false;
  }
}