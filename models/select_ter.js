const DB = require('./dbConnect');

function getRole(user){
  return user.roles.map(role => role.Name.toLowerCase()).find(role => {
    return role === 'republic' || role === 'oblast' || role === 'region' || role === 'lpu'
  });
}

async function getTer2(params = {}){
  let result = [];
  let { ter2_id = 0 } = params;

  let qParams = Number(ter2_id) !== 0 ? `WHERE CONVERT(varchar(2), id) = '${ter2_id}'` : '';
  let sql = `SELECT id, full_name AS name FROM glb_Ter2 ${qParams} ORDER BY id`;

  const queryResult = await DB.QUERY_ASYNC(sql);

  if (ter2_id) {
    result = queryResult.recordset;
  } else {
    result = queryResult.recordset.concat({
      id: 10,
      name: 'Кыргызская Республика'
    });
  }

  return result;
}

async function getTer3(params = {}){
  let {id_or_name, ter2_id} = params;
  let qParamsList = [];
  let queryCondition = '';

  if(id_or_name){ qParamsList.push(`(CONVERT(varchar, id) = ${id_or_name} OR full_name LIKE '%${id_or_name}%')`) }
  if(ter2_id){ qParamsList.push(`ter2_id = ${ter2_id}`) }
  if(qParamsList.length){ queryCondition = `WHERE ${qParamsList.join(" AND ")}`}

  let sql = `SELECT TOP 15 id, full_name AS name FROM glb_Ter3 ${queryCondition} ORDER BY id`;
  const queryResult = await DB.QUERY_ASYNC(sql);

  let result = queryResult.recordset;

  return result;
}

async function getLpu(params = {}, user){
  const currentRole = getRole(user);
  let {id_or_name, ter2_id, ter3_id} = params;
  let qParamsList = [];
  let queryCondition = '';

  if(currentRole === 'lpu'){
    id_or_name = user.GsvId
  }

  qParamsList.push('child.end_date IS NULL');

  if(id_or_name){
    qParamsList.push(`(child.id = ${id_or_name} OR child.code = ${id_or_name} OR parent.code = ${id_or_name} OR parent.id = ${id_or_name})`);
  }
  if(ter2_id){ qParamsList.push(`child.ter2_id = ${ter2_id}`) }
  if(ter3_id){ qParamsList.push(`child.ter3_id = ${ter3_id}`) }

  if(qParamsList.length){ queryCondition = `WHERE ${qParamsList.join(" AND ")} `}

  let sql = `SELECT TOP 100 child.id, coalesce(child.parent_id, child.id) AS parent_id, child.code, 
                concat(child.code, ' - ', child.short_name) AS text,
                concat(coalesce(parent.code, child.code), ' - ', coalesce(parent.short_name, child.short_name)) AS parent_name,
                IIF(child.parent_id IS NULL, 1, 0) AS is_parent
             FROM glb_lpu AS child
             LEFT JOIN glb_lpu AS parent ON child.parent_id = parent.id 
             ${queryCondition} 
             ORDER BY is_parent DESC, code ASC`

  const queryResult = await DB.QUERY_ASYNC(sql);

  const groupBy = (array, key) => {
    let groupedLpu = array.reduce((result, currentValue) => {
      (result[currentValue[key]] = result[currentValue[key]] || []).push(
        {
          id: JSON.stringify(currentValue),
          id_raw: currentValue,
          text: currentValue.text
        }
      );
      return result;
    }, {});

    return Object.keys(groupedLpu).map(lpuId => {
      // insert into @glbLPU(parent_id, id, code, short_name) values (-1, -1, null, 'ВсеГСВ')
      // insert into @glbLPU(parent_id, id, code, short_name) values (-2, -2, null, 'УзСпециалисты')
      let lpu = groupedLpu[lpuId][0].id_raw
      let parent_name = groupedLpu[lpuId][0].id_raw.parent_name;

      groupedLpu[lpuId].unshift({
        id: JSON.stringify({id: -1, parent_id: lpu.parent_id,
          code: null, text: 'ВсеГСВ', is_parent: 1, parent_name: lpu.parent_name}),
        text: 'ВсеГСВ'
      });
      groupedLpu[lpuId].unshift({
        id: JSON.stringify({id: -2, parent_id: lpu.parent_id,
          code: null, text: 'УзСпециалисты', is_parent: 1, parent_name: lpu.parent_name}),
        text: 'УзСпециалисты'
      });

      return {
        name: lpuId,
        children: groupedLpu[lpuId]
      }
    })
  };

  return groupBy(queryResult.recordset, 'parent_name')
}


async function select(req, res){
  let result = [];

  switch(req.query.terType) {
    case 'ter2_id':
      result = await getTer2(req.query);
      break;
    case 'ter3_id':
      result = await getTer3(req.query);
      break;
    case 'lpu_id':
      result = await getLpu(req.query, req.user);
      break;
  }

  res.json(result);
}

module.exports = select