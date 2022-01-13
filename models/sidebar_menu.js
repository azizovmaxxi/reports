const DB = require('../models/dbConnect');

function buildMenu(data){
  let rptList = data.filter(rpt => !rpt.parent_id);

  return rptList.map(rpt => {
    let childs = [];

    data.forEach((child) => {
      if(rpt.id === child.parent_id){
        childs.push(child)
      }
    });
    rpt.childs = childs;
    return rpt;
  })
}

async function getMenu(){
  try {
    const aReports = await DB.QUERY_ASYNC("SELECT id, parent_id, full_name, system_name, visible FROM glb_A_rpt ORDER BY id");
    const mReports = await DB.QUERY_ASYNC("SELECT id, parent_id, full_name, system_name, visible FROM glb_M_rpt ORDER BY id");
    return {aReports: buildMenu(aReports.recordset), mReports: buildMenu(mReports.recordset)};
    // return buildMenu(results.recordset)
  } catch(err) {
    throw err
  }
}

module.exports = getMenu;