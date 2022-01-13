/*
* Штаты, деятельность ГСВ по специальностям
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
  res.render('reports/rpt2_2/report_2_2');
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
        throw "For current role don't report_2_2";
      //  TODO For other roles
      default:
        throw "For current role don't report_2_2";
    }

  } catch(err){
    res.status(400).send(err);
  };
}

async function _lpu_report(req, res) {
  let params = _buildParams(req.body);
  let sqlResult = await DB.EXEC_ASYNC("rpt_2_2", params.sqlParams);

  res.render('reports/rpt2_2/rpt_2_2_result', {layout: false, data: _calcResultData(sqlResult.recordset, params), titleData: params.titleParams});
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
      lpu_title: buildLpuTitle(lpu),
      csm_name: lpu.parent_name
    },
    sqlParams: {
      sdate: sdate,
      edate: edate,
      lpu_id: lpu.id,
      lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id
    }
  };
}

function _calcResultData(data, params){
  let key = 'build_group_title';
  let sumTotalResult = {narrowSpecialist: {}, allGSV: {}, csm: {}};

  let grouped = data.reduce(function(groupObj, record) {
    sumTotalResult = _sumTotal(sumTotalResult, record);

    groupObj[record[key]] = groupObj[record[key]] || {};

    (groupObj[record[key]]['all']  = groupObj[record[key]]['all'] || []).push(record);
    groupObj[record[key]]['sum']   = _sumCols(groupObj[record[key]]['sum'], record);
    groupObj[record[key]]['title'] = record[key];
    groupObj[record[key]]['parent_id'] = record['parent_id'];
    groupObj[record[key]]['lpu_id'] = record['lpu_id'];

    return groupObj;
  }, {});

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

  return {sumTotal: sumTotalResult, allRecords: result};
}

function _sumCols(sum = {}, record = {}){
  if(sum['a1'] == undefined) {
    sum = {a1: 0, a2: 0, a3: 0, a4: 0, a5: 0, a6: 0, a7: 0, a8: 0, a9: 0}
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
  return sum;
}

function _sumTotal(sumTotalResult = {}, record = {}){
  // sumTotalResult = {narrowSpecialist: {}, allGSV: {}, csm: {}};

  if(record.parent_id == null){
    sumTotalResult['narrowSpecialist'] = _sumCols(sumTotalResult['narrowSpecialist'], record)
  } else if(record.parent_id != null){
    sumTotalResult['allGSV'] = _sumCols(sumTotalResult['allGSV'], record)
  }

  sumTotalResult['csm'] = _sumCols(sumTotalResult['csm'], record);

  return sumTotalResult;
}

module.exports = {
  getReport_2_2: getReport,
  resReport_2_2: resReport
};