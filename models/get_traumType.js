const DB = require('./dbConnect');

async function getTraumType(req, res){
    let strSql = "select code, full_name from glb_A_trauma_type";
    let result = await DB.QUERY_ASYNC(strSql);

    result.recordset.push({code: 25, full_name: 'Код не указан'});

    res.json(result.recordset);
}

module.exports = getTraumType;