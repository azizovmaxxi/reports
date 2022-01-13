const DB = require('./dbConnect');

//get Trauma type code
async function getVistypCode(params = {}){
    let {visittype} = params;
    let qParams = visittype ? `WHERE full_name LIKE '%${visittype}%' OR CONVERT(varchar, code) = ${visittype}` : '';
    let sql = `SELECT TOP 30 code, full_name FROM glb_A_visit_type ${qParams} ORDER BY code`;

    const queryResult = await DB.QUERY_ASYNC(sql);
    return queryResult.recordset;
}

async function getVisitType(req, res){
    res.json(await getVistypCode(req.query));
}

module.exports = getVisitType;