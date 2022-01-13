const DB = require('./dbConnect');

function getRole(user){
  return user.roles.map(role => role.Name.toLowerCase()).find(role => {
    return role === 'republic' || role === 'oblast' || role === 'region' || role === 'lpu'
  });
}

async function getListDoctors(params = {}, user){
  const currentRole = getRole(user);
  let {doctor_name, lpu_id} = params;
  lpu_id = JSON.parse(lpu_id);

  let qRawParams = [];
  let qParams = {};
  let queryCondition = '';

  if(currentRole === 'lpu' && (user.GsvId != lpu_id.id && user.GsvId != lpu_id.parent_id)){ return [] }

  if(lpu_id.is_parent){
    qRawParams.push('(lpu.id = @lpu_id OR lpu.parent_id = @lpu_id)');
    qParams['lpu_id'] = lpu_id.parent_id;
  } else {
    qRawParams.push('lpu.id = @lpu_id');
    qParams['lpu_id'] = lpu_id.id
  }

  if(doctor_name){
    qRawParams.push(`(doctor.name LIKE '%' + @doctor_name + '%' OR CONVERT(VARCHAR, doctor.code) = @doctor_name)`);
    qParams['doctor_name'] = doctor_name
  }

  if(qRawParams.length){ queryCondition = `WHERE ${qRawParams.join(" AND ")}`}

  let sql = `
    SELECT doctor.id, doctor.name, doctor.code AS code_kdr, doctor.lpu_id, doctor.name AS name_format
           -- spp.post_code, gSp.full_name AS post_name,
           -- concat(doctor.name, '(', spp.post_code, ' - ', gSp.full_name ,')') AS name_format
    FROM P_doctor AS doctor
      JOIN glb_lpu AS lpu ON doctor.LPU_ID = lpu.id
      --JOIN S_person_post AS spp ON doctor.CODE = spp.pers_id AND doctor.LPU_ID = spp.lpu_id
      --JOIN glb_S_post gSp ON spp.post_code = gSp.code
    ${queryCondition}
    ORDER BY name
  `;

  const queryResult = await DB.QUERY_ASYNC(sql, qParams);
  return queryResult.recordset;
}

async function getDoctor(req, res){
  let result = [];

  if(req.query.lpu_id){
    result = await getListDoctors(req.query, req.user);
  }

  res.json(result);
}

module.exports = getDoctor