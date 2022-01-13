const DB = require('./dbConnect');

async function getListICD10(params = {}){
    let {icd10} = params;
    let qParams = icd10 ? `WHERE icd10 LIKE '${icd10}%'` : '';
    let sql = `SELECT TOP 30 icd10, disease FROM glb_icd10 ${qParams} ORDER BY icd10`;

    const queryResult = await DB.QUERY_ASYNC(sql);
    return queryResult.recordset;
}

async function getIcd10(req, res){
    res.json(await getListICD10(req.query));
}

module.exports = getIcd10;