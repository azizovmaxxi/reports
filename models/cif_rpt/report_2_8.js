/*
* Показатели смешанного приема врачей ГСВ
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('reports/rpt2_8/report_2_8');
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
                throw "For current role don't report_2_8";
            //  TODO For other roles
            default:
                throw "For current role don't report_2_8";
        }

    } catch(err){
        res.status(400).send(err);
    };
}

async function _lpu_report(req, res) {
    let params = _buildParams(req.body);
    let sqlResult = await DB.EXEC_ASYNC("rpt_2_8", params.sqlParams);
    let grouped = _groupingData(sqlResult.recordset);
    let resultData = Object.keys(grouped).map((el) => {
        grouped[el]['sum'] = {...grouped[el]['sum'], ..._calcPercentSum(grouped[el]['sum'])};
        return grouped[el];
    });

    let test = _calcTotal(resultData);
    res.render('reports/rpt2_8/rpt_2_8_result', {layout: false, data: resultData, titleData: params.titleParams,
        totalSum: _calcTotal(resultData)});
}

function _buildParams(data) {
    let {sdate, edate, lpu_id} = data;
    if(!lpu_id){ throw "Выберите организацию"};
    let lpu = JSON.parse(lpu_id);
    lpu.parent_id = (lpu.id === lpu.parent_id) ? null : lpu.parent_id;
    if(lpu.parent_id){ throw "Выберите только 'ЦСМ'"};

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
            lpu_parent_id: lpu.parent_id
        }
    };
}

function _groupingData(data) {
    let key = 'lpu_code';
    return data.reduce(function (groupObj, record) {
        groupObj[record[key]] = groupObj[record[key]] || {};

        groupObj[record[key]]['title'] = `${record['lpu_name']}(${record[key]})`;
        (groupObj[record[key]]['all'] = groupObj[record[key]]['all'] || []).push(record);
        groupObj[record[key]]['sum'] = _sumCols(groupObj[record[key]]['sum'], record);

        return groupObj;
    }, {});
}

function _sumCols(sum = {}, record = {}){
    if(sum['c1'] == undefined) {
        sum = {c1: 0, c2: 0, c3: 0, c4: 0, c5: 0, c6: 0}
    }

    sum['c1'] += record['c1'];
    sum['c2'] += record['c2'];
    sum['c3'] += record['c3'];
    sum['c4'] += record['c4'];
    sum['c5'] += record['c5'];
    sum['c6'] += record['c6'];
    return sum;
}

function _calcPercentSum(sumData){
    return {
        percent_c2: sumData.c1 ? Math.ceil(sumData.c2*100/sumData.c1) : 0,
        percent_c3: sumData.c1 ? Math.ceil(sumData.c3*100/sumData.c1) : 0,
        percent_c5: sumData.c4 ? Math.ceil(sumData.c5*100/sumData.c4) : 0,
        percent_c6: sumData.c4 ? Math.ceil(sumData.c6*100/sumData.c4) : 0
    }
}

function _calcTotal(rows){
    return rows.reduce((total, row) => {
        total = _sumCols(total, row.sum);
        return {...total, ..._calcPercentSum(total) }
    },{})
}

module.exports = {
    getReport_2_8: getReport,
    resReport_2_8: resReport
};