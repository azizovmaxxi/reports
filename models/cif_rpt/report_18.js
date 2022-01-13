/*
* Обработка отчета - Медицинские наблюдение за больными ГБ
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');
var lRole;
var params;

function getReport(req, res){
    res.render('reports/rpt18/report_18');
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

async function _lpu_report(req, res) {
    params='';
    params = _buildParams(req.body);
    let options = Object.keys(params.sqlParams).map((key)=>{
    return encodeURIComponent(key)+'='+encodeURIComponent(params.sqlParams[key]);
    }).join('&');

    let sqlResult = await DB.EXEC_ASYNC("rpt_18", params.sqlParams);
    res.render('reports/rpt18/rpt_18_result', {layout: false, data:sqlResult.recordset, 
                        titleData: params.titleParams, options});
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

module.exports = {
    getReport_18: getReport,
    resReport_18: resReport
};