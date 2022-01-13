/*
* Обработка отчета Структура умерших
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('reports/rpt2_7/report_2_7');
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
    let params = _buildParams(req.body);

    let sqlResult = await DB.EXEC_ASYNC("rpt_2_7", params.sqlParams);
    res.render('reports/rpt2_7/rpt_2_7_result', {layout: false, data: sqlResult.recordset, 
                        titleData: params.titleParams});
}

function _buildParams(data) {
    let {sdate, edate, lpu_id, age, sex_id} = data;
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
            sex_id: (sex_id ? (sex_id=='0'?'Женщины':'Мужчины'): null),
            age: _age_title(age)
        },
        sqlParams: {
            sdate: sdate,
            edate: edate,
            lpu_id: lpu.id,
            lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
            age: age ? age : null,
            sex_id: sex_id ? sex_id : null
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

function _age_title(age){
    switch (age) {
        case '_14':
            return 'Дети до 14 лет включительно';
        case '_15_17':
            return 'Подростки (15-17 лет)';
        case 'adult_teenager':
            return 'Взрослые и подростки';
        case 'adult':
            return 'Взрослые';
        default: return null;
    }
}

module.exports = {
    getReport_2_7: getReport,
    resReport_2_7: resReport,
};