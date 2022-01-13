/*
* Обработка отчета - АД. Число случаев поликлинического обслуживания
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');
const { map } = require('mssql');
var lRole;
var params;

function getReport(req, res){
    res.render('reports/rpt13/report_13');
}

async function resReport(req, res){
    lRole = getUserRole(req);
    try
    {
        switch(lRole){
            case 1: 
                await _lpu_report(req, res);
                break;
            case 2:
                throw "У вас нет прав доступа! Обратитесь к администратору сервера";
            //  TODO For other roles
            case 0:
                throw "У вас нет прав доступа! Обратитесь к администратору сервера";
        }
  
    } catch(err){
        res.status(400).send(err);
    };
}

function getUserRole(req){

    //Роль пользователя для формирования отчета
    switch(getRole(req.user)){
        case 'lpu': //формирование отчетов на уровне организации
            return 1;
        case 'republic'://формирование отчетов на уровне республики
            return 2;
        //  TODO For other roles
        default:
            return 0;
    }
}

async function _lpu_report(req, res) {
    params='';
    params = _buildParams(req.body);

    let sqlResult = await DB.EXEC_ASYNC("rpt_13", params.sqlParams);
    res.render('reports/rpt13/rpt_13_result', {layout: false, data:sqlResult.recordset, 
                        titleData: params.titleParams});
}

function _buildParams(data) {
    let {sdate, edate, lpu_id, type_rpt} = data;
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
            type_rpt: (type_rpt === 'cases' ? 'По случаям' : 'По заболеваниям(ГБ)')
        },
        sqlParams: {
            sdate: sdate,
            edate: edate,
            lpu_id: lpu.id,
            lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
            type_rpt: type_rpt
        }
    };
}

module.exports = {
    getReport_13: getReport,
    resReport_13: resReport
};