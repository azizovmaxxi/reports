/*
* Штаты, деятельность ГСВ по должностям
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
  res.render('reports/rpt2_3/report_2_3');
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
        throw "For current role don't report_2_3";
      //  TODO For other roles
      default:
        throw "For current role don't report_2_3";
    }

  } catch(err){
    res.status(400).send(err);
  };
}

async function _lpu_report(req, res){
  let params = _buildParams(req.body);
  let result = await _buildRenderResult(params);

  res.render('reports/rpt2_3/rpt_2_3_result', {layout: false, titleData: params.titleParams, ...result});
}

async function _buildRenderResult(params){
  let sqlResult=[];
  let resultData = svodCsm = svodAllGsv = null;

  if (params.sqlParams.lpu_id)
  {
    sqlResult = await DB.EXEC_ASYNC("rpt_2_3", params.sqlParams);
  }else
  {
    sqlResult = await DB.EXEC_ASYNC("rpt_more2_3", params.sqlMoreParams);
  }

  let sumTotal = _sumTotal(sqlResult.recordset);

  if(!params.titleParams.svod_csm && !params.titleParams.svod_all_gsv){
    resultData = _calcResultData(sqlResult.recordset, params)
  }

  if(params.titleParams.svod_csm){
    svodCsm = _svod(sqlResult.recordset, 'svod_csm');
  }

  if(params.titleParams.svod_all_gsv){
    svodAllGsv = _svod(sqlResult.recordset, 'svod_all_gsv');
  }

  return {data: resultData || [], svod_csm: svodCsm || [], svod_all_gsv: svodAllGsv || [], sum_total: sumTotal}
}

function _buildParams(data) {
  let lpu={};
  let lpuCode="";
  let doctors="";

  let {sdate, edate, lpu_id, svod_csm, 
       svod_all_gsv, lpu_code, gsvname, doctor, doctorname} = data;
  if(!lpu_id && !lpu_code){ throw "Выберите организацию" };
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
      svod_csm: svod_csm,
      svod_all_gsv: svod_all_gsv,
      gsvname: gsvname,
      doctorname: doctorname
    },
    sqlParams: {
      sdate: sdate,
      edate: edate,
      lpu_id: (svod_all_gsv || svod_csm) ? lpu.parent_id : lpu.id,
      lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
    },
    sqlMoreParams: {
        sdate: sdate,
        edate: edate,
        lpu_code: lpuCode? lpuCode : null,
        doctors: doctors? doctors : null
    }
  };
}

function _calcResultData(data, params){
  let key = 'build_group_title';
  let grouped = _groupingData(data, key);

  let result = Object.keys(grouped).map((el) => { return grouped[el] })
      .filter((lpu) => {
        if(params.sqlParams.lpu_id == -2){
          return lpu.parent_id == null
        } else if(params.sqlParams.lpu_id == -1){
          return lpu.parent_id != null
        } else if(params.sqlParams.lpu_parent_id != null){
          return lpu.lpu_id == params.sqlParams.lpu_id
        } else {
          return true
        }
      });

  return result;//{sumTotal: _sumTotal(data), allRecords: result};
}

function _sumCols(sum = {}, record = {}){
  if(sum['a1'] == undefined) {
    sum = {a1: 0, a2: 0, a3: 0, a4: 0, a5: 0, a6: 0, a7: 0, a8: 0, a9: 0, a10: 0}
  }

  sum['a1'] += record['a1'];
  sum['a2'] += record['a2'];
  sum['a3'] += record['a3'];
  sum['a4'] += record['a4'];
  sum['a5'] += record['a5'];
  sum['a6'] += record['a6'];
  sum['a7'] += record['a7'];
  sum['a8'] += record['a8'];
  sum['a9'] += record['a9'];
  sum['a10'] += record['a10'];
  return sum;
}

// function _sumTotal(sumTotalResult = {}, record = {}){
function _sumTotal(data){
  let sumTotalResult = {narrowSpecialist: {}, allGSV: {}, csm: {}};

  data.forEach((record) => {
    if(record.parent_id == null){
      sumTotalResult['narrowSpecialist'] = _sumCols(sumTotalResult['narrowSpecialist'], record)
    } else if(record.parent_id != null){
      sumTotalResult['allGSV'] = _sumCols(sumTotalResult['allGSV'], record)
    }

    sumTotalResult['csm'] = _sumCols(sumTotalResult['csm'], record);
  });

  return sumTotalResult;
}

function _svod(rawData, type){
  let key = 'post_name';
  let data = type == 'svod_all_gsv' ? rawData.filter((record)=> {return record.parent_id != null}) : rawData;
  let grouped = _groupingData(data, key);

  return Object.keys(grouped).map((el) => { return grouped[el] })
}

function _groupingData(data, key){
  return data.reduce(function(groupObj, record){
    groupObj[record[key]] = groupObj[record[key]] || {};

    (groupObj[record[key]]['all']  = groupObj[record[key]]['all'] || []).push(record);
    groupObj[record[key]]['sum']   = _sumCols(groupObj[record[key]]['sum'], record);
    groupObj[record[key]]['title'] = record[key];
    groupObj[record[key]]['parent_id'] = record['parent_id'];
    groupObj[record[key]]['lpu_id']    = record['lpu_id'];

    return groupObj;
  }, {});
}

module.exports = {
  getReport_2_3: getReport,
  resReport_2_3: resReport
};