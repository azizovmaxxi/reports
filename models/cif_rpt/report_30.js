/*
* Процент женщин у которых проведен осмотр шейки матки
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('reports/rpt30/report_30');
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
                throw "For current role don't report_30";
            //  TODO For other roles
            default:
                throw "For current role don't report_30";
        }

    } catch(err){
        res.status(400).send(err);
    };
}

async function _lpu_report(req, res) {
    let params = _buildParams(req.body);
    let sqlResult = await DB.EXEC_ASYNC("rpt_30", params.sqlParams);

    res.render('reports/rpt30/rpt_30_result', {layout: false, data: sqlResult.recordset, titleData: params.titleParams});
}

function _buildParams(data) {
    let {sdate, edate, lpu_id} = data;
    if(!lpu_id){ throw "Выберите организацию"};
    let lpu = JSON.parse(lpu_id);

    return {
        titleParams: {
            sdate: sdate,
            edate: edate,
            code: lpu.code,
            lpu_id: lpu.id,
            lpu_title: buildLpuTitle(lpu),
            csm_name: lpu.parent_name,
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
    getReport_30: getReport,
    resReport_30: resReport
};