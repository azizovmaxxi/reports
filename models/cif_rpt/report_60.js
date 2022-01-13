/*
* Отчет - Возрастная структура женщин репродуктивного
* возраста медико-социальной группы риска
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('reports/rpt60/report_60');
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

    let params = await _buildParams(req.body);

    let sqlResult = await DB.EXEC_ASYNC("rpt_60", params.sqlParams);

    switch (params.sqlParams.rpt_type) {
        case 2:
            res.render('reports/rpt60/rpt_60_result2', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
            break;
        case 3:
            res.render('reports/rpt60/rpt_60_result3', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
            break;
        case 4:
            res.render('reports/rpt60/rpt_60_result4', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
            break;
        case 5:
            res.render('reports/rpt60/rpt_60_result5', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
            break;
        case 6:
            res.render('reports/rpt60/rpt_60_result6', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
            break;
        case 7:
            res.render('reports/rpt60/rpt_60_result7', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
            break;
        case 8:
            res.render('reports/rpt60/rpt_60_result8', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
            break;
        case 9:
            res.render('reports/rpt60/rpt_60_result9', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
            break;
        case 10:
            res.render('reports/rpt60/rpt_60_result10', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
            break;
        case 11:
            res.render('reports/rpt60/rpt_60_result11', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
            break;
        case 12:
            res.render('reports/rpt60/rpt_60_result12', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
            break;
        default:
            res.render('reports/rpt60/rpt_60_result', { 
                layout: false, 
                data: sqlResult.recordset, 
                titleData: params.titleParams 
            });
    }

}

async function _buildParams(data) {
    let lpu = {};
    let ter_name = [];

    const {
        sdate, 
        edate, 
        lpu_id = null, 
        rpt_list,
        rpt_name,
        ter2_id = 0 } = data;

    if (!lpu_id && !ter2_id){ throw "Выберите организацию или область"};
    if (lpu_id) { lpu = JSON.parse(lpu_id) };

    if (ter2_id) {
      if (Number(ter2_id) === 10) {
          ter_name.push({
              id: 10,
              full_name: 'Кыргызская Республика'
              })
      } else {
          ter_name = await getTer2(Number(ter2_id))
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
            rpt_name: rpt_name,
            ter_name: !ter2_id?"":ter_name[0].full_name
        },
        sqlParams: {
            sdate: sdate,
            edate: edate,
            lpu_id: lpu.id,
            lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
            rpt_type: Number(rpt_list),
            terId: Number(ter2_id) 
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

async function getTer2(Id){
    let sql = `select id, full_name from glb_Ter2 where id=${Id}`;

    sqlResult = await DB.QUERY_ASYNC(sql);

    return sqlResult.recordset;
}

module.exports = {
    getReport_60: getReport,
    resReport_60: resReport
}