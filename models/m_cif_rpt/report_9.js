/*
* Отчет - Процедуры, манипуляции, анализы, выполненные специалистом сестринского дела
*/
const DB = require('../dbConnect');
const xml = require('fast-xml-parser');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('m_reports/rpt9/report_9');
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
                throw "For current role don't report_9";
                break;
            //  TODO For other roles
            default:
                throw "For current role don't report_9";
        }

    } catch(err){
        res.status(400).send(err);
    };
}

async function _lpu_report(req, res) {
    let params = _buildParams(req.body);
    let sqlResult = await DB.EXEC_ASYNC("m_rpt_9", params.sqlParams);
    let resultData = _xmlParse(sqlResult.recordset[0]);
    if(!Object.keys(resultData).length){ throw "По выбранным параметрам отчета данные отсутствуют!" }

    res.render('m_reports/rpt9/rpt_9_result', {layout: false, data: resultData, titleData: params.titleParams});
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
            csm_name: lpu.parent_name
        },
        sqlParams: {
            sdate: sdate,
            edate: edate,
            lpu_id: lpu.id,
            lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
        }
    };
}

function _xmlParse(data){
    return ['result_cases', 'list_procedures'].reduce((acc, col) => {
        return Object.assign(acc, xml.parse(data[col], {arrayMode: true}));
    }, {})
}

module.exports = {
    getMReport_9: getReport,
    resMReport_9: resReport
};