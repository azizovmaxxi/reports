/*
* Процент КИФ  с заполненным факторами риска
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('reports/rpt12/report_12');
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
                throw "For current role don't report_12";
            //  TODO For other roles
            default:
                throw "For current role don't report_12";
        }

    } catch(err){
        res.status(400).send(err);
    };
}

async function _lpu_report(req, res) {
    let params = _buildParams(req.body);
    let sqlResult = await DB.EXEC_ASYNC("rpt_12", params.sqlParams);

    res.render('reports/rpt12/rpt_12_result', {layout: false, data: sqlResult.recordset, titleData: params.titleParams});
}

function _buildParams(data) {
    let {sdate, edate, lpu_id, type_rpt, doctor_id, post_code} = data;
    if(!lpu_id){ throw "Выберите организацию"};
    let lpu = JSON.parse(lpu_id);
    let doctor = doctor_id ? JSON.parse(doctor_id) : null;
    let postcode = post_code ? JSON.parse(post_code) : null;

    return {
        titleParams: {
            sdate: sdate,
            edate: edate,
            code: lpu.code,
            lpu_id: lpu.id,
            lpu_title: buildLpuTitle(lpu),
            csm_name: lpu.parent_name,
            type_rpt: (type_rpt === 'diseases' ? 'По заболеваниям' : 'По случаям'),
            doctor_name: doctor ? doctor.name : null,
            post_code: postcode ? `${postcode.name}(${postcode.code})` : null,
        },
        sqlParams: {
            sdate: sdate,
            edate: edate,
            lpu_id: lpu.id,
            lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
            type_rpt: type_rpt,
            doctor_id: doctor ? doctor.id : null,
            post_code: postcode ? postcode.code : null,
        }
    };
}

module.exports = {
    getReport_12: getReport,
    resReport_12: resReport
};