/*
* Обработка отчета 1.Форма 12.Заболеваемость населения
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('reports/rpt1/report_1');
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
    
    let params = _buildParams(req.body);
    let options = Object.keys(params.sqlParams).map((key)=>{
    return encodeURIComponent(key)+'='+encodeURIComponent(params.sqlParams[key]);
    }).join('&');

    if (params.sqlParams.lpu_id)
    {
      sqlResult = await DB.EXEC_ASYNC("rpt_1", params.sqlParams);
    }else {  
        sqlResult = await DB.EXEC_ASYNC("rpt_more1", params.sqlMoreParams); 
    }

    res.render('reports/rpt1/rpt_1_result', {layout: false, data:sqlResult.recordset, 
                        titleData: params.titleParams, options});
}

function _buildParams(data) {
    let lpu={};
    let lpuCode="";
    let doctors="";

    const {
        sdate, 
        edate, 
        lpu_id, 
        type_rpt, 
        lpu_code, 
        doctor,
        gsvname,
        doctorname} = data;

    if (!lpu_id && !lpu_code && !doctor){ throw "Выберите врача или организацию"};
    if (typeof (lpu_id) !== "undefined") {lpu = JSON.parse(lpu_id)};
    if (typeof (lpu_code) !== "undefined") 
    {
        if (Array.isArray(lpu_code))
            lpuCode = lpu_code.join();
        else lpuCode = lpu_code;
    };
    if (typeof (doctor) !== "undefined") 
    {
        if(Array.isArray(doctor))
            doctors = doctor.map((e)=> "'" + e + "'");
        else doctors = "'" + doctor + "'";
    };

    return {
        titleParams: {
            sdate: sdate,
            edate: edate,
            code: lpu.code,
            lpu_id: lpu.id,
            lpu_title: buildLpuTitle(lpu),
            csm_name: lpu.parent_name,
            type_rpt: (type_rpt === 'diseases' ? 'По заболеваниям' : 'По пациентам'),
            gsvname: gsvname,
            doctorname: doctorname
        },
        sqlParams: {
            sdate: sdate,
            edate: edate,
            lpu_id: lpu.id,
            lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
            type_rpt: type_rpt
        },
        sqlMoreParams: {
            sdate: sdate,
            edate: edate,
            type_rpt: type_rpt,
            lpu_code: lpuCode? lpuCode : null,
            doctors: doctors? doctors : null
        }
    };
}

/**Формирование список пациентов */
async function getPersonList(req, res){
   let lRole = getUserRole(req);
    try
    {
        switch(lRole){
            case 1: 
                await PersonList(req, res);
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

async function PersonList(req, res){
    let params = await _buildReqParams(req.query);

    let sqlResult = await DB.EXEC_ASYNC("rpt_1_revision", params.sqlParams);
    res.render('reports/rpt1/rpt_1_revision', {layout: false, data:sqlResult.recordset, titleData: params.titleParams});
}

async function _buildReqParams(data)
{
    let {row, col, sdate, edate, lpu_id, lpu_parent_id, type_rpt} = data;
    if(row==0 || col==0){ throw "Неправильно указаны параметры при запросе"};
        let rowname= await getRptRow(Number(row));
        let colname= await getRptCol(Number(col));
    return {
        titleParams: {
            rowname: rowname,
            colname:colname,
            sdate: sdate,
            edate: edate,
            type_rpt: (type_rpt === 'diseases' ? 'По заболеваниям' : 'По пациентам')
        },
        sqlParams: {
            row: Number(row),
            col: Number(col),
            sdate: sdate,
            edate: edate,
            lpu_id: Number(lpu_id),
            lpu_parent_id: (lpu_parent_id === 'null') ? null : lpu_parent_id,
            type_rpt: type_rpt,
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

async function getRptRow(row){
    let sql ='select code + \' - \' + full_name + case when icd10 is null then \'\' else \'(\' + icd10 + \')\' end rowname from glb_A_rpt_rows where num=@num'
    let result = await DB.QUERY_ASYNC(sql, {num:row});
    return result.recordset[0].rowname;
}

async function getRptCol(col){
    let sql ='select full_name from glb_A_rpt_collumns where rpt_id=1 and num=@num'
    let result = await DB.QUERY_ASYNC(sql, {num:col});
    return result.recordset[0].full_name;
}

module.exports = {
    getReport1: getReport,
    resReport1: resReport,
    getPersonList1: getPersonList
};