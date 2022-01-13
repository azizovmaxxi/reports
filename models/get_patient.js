const DB = require('./dbConnect');

function getRole(user){
  return user.roles.map(role => role.Name.toLowerCase()).find(role => {
    return role === 'republic' || role === 'oblast' || role === 'region' || role === 'lpu'
  });
}

async function getListPatients(params = {}, user){
  const currentRole = getRole(user.toJSON());
  let {patient_name, lpu_id} = params;
  lpu_id = JSON.parse(lpu_id);
  if(!lpu_id){ throw "Выберите организацию" };

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

  if(patient_name){
    qRawParams.push(`(concat(p_p.last_name, ' ', p_p.first_name, ' ', p_p.mid_name) LIKE '%' + @patient_name + '%')`);
    qParams['patient_name'] = patient_name
  }

  if(qRawParams.length){ queryCondition = `WHERE ${qRawParams.join(" AND ")}`}

  let sql = `
    SELECT TOP 20 p_p.id, concat(last_name, ' ', first_name, ' ', coalesce(mid_name, '')) AS full_name,
       FORMAT (p_p.birth_day, 'dd.MM.yyyy') AS birth_day, LEFT(gsv_id, 4) AS gsv_code, soc_id AS pin, sex_id,
       CONCAT(streets.name, ' ', p_addr.house, ' ', coalesce(p_addr.flat, ''), ' ', coalesce(phone, '')) AS address
    FROM P_PERSON AS p_p
    INNER JOIN P_PersonAssignment AS p_pa ON p_p.id = p_pa.person_id
    INNER JOIN glb_lpu AS lpu ON p_pa.gsv_id = lpu.id
    INNER JOIN p_address AS p_addr ON p_p.address_id = p_addr.id
    INNER JOIN glb_Streets AS streets on p_addr.street_id = streets.id
    ${queryCondition}
    ORDER BY full_name
  `;

  const queryResult = await DB.QUERY_ASYNC(sql, qParams);
  return queryResult.recordset;
}

async function getPatient(req, res){
  let result = [];

  if(req.query.lpu_id){
    result = await getListPatients(req.query, req.user);
  }

  res.json(result);
}

module.exports = getPatient;