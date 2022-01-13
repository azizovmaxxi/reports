/*
* Отчет - Население по возрастам и по полу
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('reports/rpt58/report_58');
}

async function resReport(req, res){
    let lRole = getUserRole(req);
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
    let sqlResult=[];
    let age = ['100', '101', '102', '103', '104', '105',
               '106', '107', '108', '109', '110', '111',
               '112', '113', '114', '115', '116', '117'];
    
    let params = _buildParams(req.body);
    sqlResult = await DB.EXEC_ASYNC("rpt_58", params.sqlParams);

    let result = sqlResult.recordset.filter(item => !age.includes(item.age));


    res.render('reports/rpt58/rpt_58_result', {layout: false, 
                        data:result, titleData: params.titleParams });
}

function _buildParams(data) {
    let lpu = {};
    let lpuCode = "";

    const {
        sdate, 
        edate, 
        lpu_id, 
        lpu_code, 
        gsvname} = data;

    if (!lpu_id && !lpu_code){ throw "Выберите организацию"};
    if (typeof(lpu_id) !== 'undefined') { lpu = JSON.parse(lpu_id) };
    if (typeof(lpu_code) !== 'undefined') 
    {
        if (Array.isArray(lpu_code))
        {
          lpuCode = lpu_code.join();
        }else {
          lpuCode = lpu_code;
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
            gsvname: gsvname
        },
        sqlParams: {
            sdate: sdate,
            edate: edate,
            lpu_id: lpu.id,
            lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
            GsvId: lpuCode? lpuCode: null
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
    getReport_58: getReport,
    resReport_58: resReport
}