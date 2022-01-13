const DB = require('./dbConnect');

async function getPostCode(params = {}){
  let {code_or_name} = params;
  let qParams = code_or_name ? `WHERE CONVERT(varchar, code) = '${code_or_name}' OR full_name LIKE '%${code_or_name}%'` : '';
  let sql = `SELECT TOP 50 code, full_name AS name FROM glb_s_post ${qParams} ORDER BY code`;

  const queryResult = await DB.QUERY_ASYNC(sql);
  return queryResult.recordset;
}

async function getPostCodeList(req, res){
  let result = await getPostCode(req.query);
  res.json(result);
}

module.exports = getPostCodeList;