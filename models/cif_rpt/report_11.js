/*
* Курение
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('reports/rpt11/report_11');
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
                throw "For current role don't report_11";
            //  TODO For other roles
            default:
                throw "For current role don't report_11";
        }

    } catch(err){
        res.status(400).send(err);
    };
}

async function _lpu_report(req, res) {
    let params = _buildParams(req.body);
    let sqlResult = await DB.EXEC_ASYNC("rpt_11", params.sqlParams);

    res.render('reports/rpt11/rpt_11_result', {layout: false, data: sqlResult.recordset, titleData: params.titleParams});
}

function _buildParams(data) {
    let {sdate, edate, lpu_id, icd10_start, icd10_end} = data;
    if(!lpu_id){ throw "Выберите организацию"};
    let lpu = JSON.parse(lpu_id);
    if((!icd10_start && icd10_end) || (icd10_start && !icd10_end) ){throw "Не правильно заполнен диапазон МКБ-10"}

    return {
        titleParams: {
            sdate: sdate,
            edate: edate,
            code: lpu.code,
            lpu_id: lpu.id,
            lpu_title: buildLpuTitle(lpu),
            csm_name: lpu.parent_name,
            icd10: (icd10_start && icd10_end) ? `${icd10_start} - ${icd10_end}` : null
        },
        sqlParams: {
            sdate: sdate,
            edate: edate,
            lpu_id: lpu.id,
            lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
            icd10_start: icd10_start ? icd10_start : null,
            icd10_end: icd10_end ? icd10_end : null
        }
    };
}

module.exports = {
    getReport_11: getReport,
    resReport_11: resReport
};