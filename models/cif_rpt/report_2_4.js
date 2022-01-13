/*
* Помощь при неотложных состояниях
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
  res.render('reports/rpt2_4/report_2_4');
}

async function resReport(req, res){
  try
  {
    //Вытаскивать отчет в зависимости от роли, т.к. один отчет по разному вычисляется
    switch(getRole(req.user)){
      case 'lpu':
        await _lpu_report(req, res);
        break;
      case 'republic':
        throw "For current role don't report_2_4";
        break;
      //  TODO For other roles
      default:
        throw "For current role don't report_2_4";
    }

  } catch(err){
    res.status(400).send(err);
  };
}

async function _lpu_report(req, res) {
  let sqlResult=[];
  let params = _buildParams(req.body);

  if (params.sqlParams.lpu_id)
  {
      sqlResult = await DB.EXEC_ASYNC("rpt_2_4", params.sqlParams);
  }
  else{  sqlResult = await DB.EXEC_ASYNC("rpt_more2_4", params.sqlMoreParams);  }

  res.render('reports/rpt2_4/rpt_2_4_result', {layout: false, data: sqlResult.recordset, titleData: params.titleParams});
}

function _buildParams(data) {
  let lpu={};
  let lpuCode="";
  let doctors="";

  let {sdate, edate, 
    lpu_id, lpu_code, 
    doctor, gsvname,
    doctorname} = data;

  if(!lpu_id && !lpu_code && !doctor){ throw "Выберите организацию"};
  if (typeof (lpu_id) !== "undefined") {lpu = JSON.parse(lpu_id)};
  if (typeof (lpu_code) !== "undefined") 
  {
      if (Array.isArray(lpu_code))
          lpuCode = lpu_code.join();
      else lpuCode = lpu_code;
  };
  if (typeof (doctor) !== "undefined") 
  {
      if(Array.isArray(doctor))
          doctors = doctor.map((e)=> "'" + e + "'");
      else doctors = "'" + doctor + "'";
  };

  return {
    titleParams: {
      sdate: sdate,
      edate: edate,
      code: lpu.code,
      lpu_id: lpu.id,
      lpu_title: buildLpuTitle(lpu),
      csm_name: lpu.parent_name,
      gsvname: gsvname,
      doctorname: doctorname
    },
    sqlParams: {
      sdate: sdate,
      edate: edate,
      lpu_id: lpu.id,
      lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id
    },
    sqlMoreParams: {
        sdate: sdate,
        edate: edate,
        lpu_code: lpuCode? lpuCode : null,
        doctors: doctors? doctors : null
    }
  };
}

module.exports = {
  getReport_2_4: getReport,
  resReport_2_4: resReport
};