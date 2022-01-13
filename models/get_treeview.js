const db = require('./dbConnect');

/**Defining the user's territory */
async function getTerrId(GsvId){
    let result = await db.QUERY_ASYNC("select ter2_id from glb_lpu where id=@id", {id:GsvId});
    return result.recordset;

}
/**Create Treeview LPO */
async function getTreeLpu (user){
    try
    {
        let userLPU = user;
        let terId = await getTerrId(userLPU.GsvId);
       

        let strSql = "select  a.parent_id, a.id value, concat(a.code, ' - ', a.short_name) name from glb_lpu a where exists " +
            "(select id from glb_lpu where org_code in (8, 2) and prof_code in (20, 9) " +
            "and type1_code=20 and end_date is null and parent_id is null and ter2_id=@id and id=a.parent_id) " +
            "union select  a.parent_id,  a.id value, concat(a.code, ' - ', a.short_name) name from glb_lpu a where org_code in (8, 2) and prof_code in (20, 9) " +
            "and type1_code=20 and end_date is null and parent_id is null and ter2_id=@id";
        let qry = await db.QUERY_ASYNC(strSql, {id:terId[0].ter2_id});
        let result = (qry.recordset);

        const treeLpu = {
            nodes: {}
        };
        const parentLPU = [];
        for (let i=0; i<result.length; i++)
        {
            if (result[i].parent_id===null)
            {
                parentLPU.push(
                    {
                        [result[i].value]:{
                        flag: false,
                        name: "lpu_code",
                        desc: result[i].name,
                        value: result[i].value,
                        nodes: getLpuChild(result[i].value, result)
                      }
                    });                
            }
        }
        
        treeLpu.nodes = Object.assign({}, ...parentLPU.map(item=>(item)));

        return treeLpu;

    } catch(e){
        console.error("Ошибка", e.lineNumber);
    }
}

/**Get child LPO */
function getLpuChild(value, array){
    let newChild = [];

    for (let i = 0; i < array.length; i++) {
        if (array[i].parent_id === value) {
            newChild.push({
                [array[i].value]: {
                    flag: false,
                    name: "lpu_code",
                    desc: array[i].name,
                    value: array[i].value
                }
            });
        }
    }
    let child = Object.assign({}, ...newChild.map(item=>(item)));

    return child;
} 

/**Create Treeview Doctors */
async function getTreeDoctors(user){
    try
    {
        let userLPU = user;

        let strSql = "select id value, concat(code, ' - ', name) name from P_doctor d " +
            "where exists(select id from glb_lpu where (id=@id or parent_id=@id) and id=d.lpu_id)" +
            "order by d.name";
        let qry = await db.QUERY_ASYNC(strSql, {id:userLPU.GsvId});
        let result = (qry.recordset);

        const treeDoc = {
            nodes: {}
        };
        const parentDoc = [];
        parentDoc.push(
            {
                doctor:{
                flag: false,
                name: "doctor",
                desc: "Врачи",
                value: "2B000000-0000-0000-0000-000000000001",
                nodes: getDoctors(result)
                }
            });                
        
        treeDoc.nodes = Object.assign({}, ...parentDoc.map(item=>(item)));

        return treeDoc;

    } catch(e){
        console.error("Ошибка", e.lineNumber);
    }
}

/**Get child Doctors */
function getDoctors(array){
    let newChild = [];

    for (let i = 0; i < array.length; i++) {
            newChild.push({
                [array[i].value]: {
                    flag: false,
                    name: "doctor",
                    desc: array[i].name,
                    value: array[i].value
                }
            });
    }
    let child = Object.assign({}, ...newChild.map(item=>(item)));

    return child;
}

async function get_treeview(req, res){
    result=[];
    switch(req.query.id){
        case "treelpu":
            result = await getTreeLpu(req.user);
            break;
        case "treedoc":
            result = await getTreeDoctors(req.user);
            break;
    }

    res.json(result);
}
module.exports = get_treeview;