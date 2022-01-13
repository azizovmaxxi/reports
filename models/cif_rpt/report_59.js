/*
* Отчет - Возрастная структура женщин репродуктивного
* возраста медико-социальной группы риска
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('reports/rpt59/report_59');
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
    let sqlResult = [];
    
    let params = _buildParams(req.body);

    sqlResult = await DB.EXEC_ASYNC("rpt_59", params.sqlParams);

    // Сортировка по коду
    let medCode = sqlResult.recordset.filter(item => item.code >= 200);
    let socCode = sqlResult.recordset.filter(item => item.code < 200);
    
    medCode.push({cat_id: null, full_name: "Группа риска по социальным показаниям", code: null,
        total: null, c2: null, c3: null, c4: null, c5: null, 
        c6: null, c7: null, c8: null, c9: null, c10: null, c11: null});
    medCode.push(...socCode);
        
    res.render('reports/rpt59/rpt_59_result', {layout: false, data:medCode, 
                        titleData: params.titleParams });
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
    getReport_59: getReport,
    resReport_59: resReport
}