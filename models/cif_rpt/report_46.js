/*
* Сведения о зарегистрированных новых случаев заболеваний  пневмонией, ОРВИ, COVID-19
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend')
const buildLpuTitle = require('../../helpers/buildLpuTitle')

function getReport(req, res){
  res.render('reports/rpt46/report_46');
}

async function resReport(req, res){
  try
  {
    //Вытаскивать отчет в зависимости от роли
    switch(getRole(req.user)){
      case 'lpu':
        await _lpu_report(req, res);
        break;
      case 'republic':
        throw "For current role don't report";
      //  TODO For other roles
      default:
        throw "For current role don't report";
    }

  } catch(err){
    res.status(400).send(err);
  };
}

async function _lpu_report(req, res) {
  let params = _buildParams(req.body);

  let sqlResult = await DB.EXEC_ASYNC("rpt_46", params.sqlParams);

  res.render('reports/rpt46/rpt_46_result', {layout: false, data: sqlResult.recordset, titleData: params.titleParams});
}

function _buildParams(data) {
  let {sdate, edate, lpu_id} = data;
  if(!lpu_id){ throw "Выберите организацию" };
  let lpu = JSON.parse(lpu_id);

  return {
    titleParams: {
      sdate: sdate,
      edate: edate,
      code: lpu.code,
      lpu_id: lpu.id,
      lpu_title: buildLpuTitle(lpu)
    },
    sqlParams: {
      sdate: sdate,
      edate: edate,
      lpu_id: lpu.id,
      lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id
    }
  };
}

module.exports = {
  getReport_46: getReport,
  resReport_46: resReport
};