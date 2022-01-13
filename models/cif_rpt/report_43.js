/*
* Посещения к врачам, ведущим амбулаторно-поликлинический прием
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend')
const buildLpuTitle = require('../../helpers/buildLpuTitle')

function getReport(req, res){
  res.render('reports/rpt43/report_43');
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
        throw "For current role don't report_43";
      //  TODO For other roles
      default:
        throw "For current role don't report_43";
    }

  } catch(err){
    res.status(400).send(err);
  };
}

async function _lpu_report(req, res) {
  let params = _buildParams(req.body);

  let sqlResult = await DB.EXEC_ASYNC("rpt_43", params.sqlParams);
  res.render('reports/rpt43/rpt_43_result', {layout: false, data: sqlResult.recordset, titleData: params.titleParams});
}

function _buildParams(data) {
  let lpu = {};
  let GsvId = "";
  let doctors="";

  const {
      sdate, 
      edate, 
      lpu_id, 
      lpu_code, 
      gsvname,
      doctor,
      doctorname} = data;

  if (!lpu_id && !lpu_code){ throw "Выберите организацию"};
  if (typeof(lpu_id) !== 'undefined') { lpu = JSON.parse(lpu_id) };
  if (typeof(lpu_code) !== 'undefined') 
  {
      if (Array.isArray(lpu_code))
      {
        GsvId = lpu_code.join();
      }else {
        GsvId = lpu_code;
      }
      if (typeof (doctor) !== "undefined") 
      {
          if(Array.isArray(doctor))
          {
            doctors = doctor.map((e)=> e);
          }else {
            doctors = doctor;
          } 
      }
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
          lpu_id: lpu.id? lpu.id : null,
          lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
          GsvId: GsvId? GsvId : null,
          doctorId: doctors? doctors : null
      }
  };
}

module.exports = {
  getReport_43: getReport,
  resReport_43: resReport
};