/*
* Обработка отчета 28.Карта оценки результатов работы семейного врача 
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const roundTo = require('round-to');

function getReport(req, res){
  res.render('reports/rpt28/report_28');
}

async function resReport(req, res){
  lRole = getUserRole(req);
  try
  {
      switch(lRole){
          case 1: 
              await getEvaluation(req, res);
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

async function getEvaluation(req, res){
  try
  {
    let params = _buildParams(req.body);

    let options = Object.keys(params.sqlParams).map((key)=>{
    return encodeURIComponent(key)+'='+encodeURIComponent(params.sqlParams[key]);
    }).join('&');

    if (params.titleParams.rpt=="rpt28"){
      if (params.titleParams.doctor===null) throw "Не указан код врача!";

      const result = await DB.EXEC_ASYNC("rpt_28", params.sqlParams);
      sumball(result.recordset);

      res.render('reports/rpt28/rpt28_result', {layout:false, qry:result.recordset, Title:params.titleParams, 
                options:options});

    }else if(params.titleParams.rpt=="rpt28_svod"){
      params.sqlParams.docId=null;
      params.sqlParams.flag=2;

      const result = await DB.EXEC_ASYNC("rpt_28", params.sqlParams);
      avgball(result.recordset);
      
      res.render('reports/rpt28/rpt28_svod', {layout:false, qry:result.recordset, Title:params.titleParams});

    }else {
      throw "Данный момент не возможно открыть отчет";
    }

  }catch(err){
     throw err;
  };   
}

function sumball(sum, key) {
  let  leve={};
  if (!Array.isArray(sum) || sum.length==0) throw "По выбранным параметрам отчета данные отсутствуют!";
      leve = sum.reduce((a,b)=>{
      return {
        id: null,
        full_name: '',
        lpu_id: null,
        docId: '',
        doc_id: null,
        fio: '',
        formula: 'ИТОГО',
        leve:a.leve+b.leve, 
        ball:a.ball+b.ball };
  });
  return sum.push(leve);
}

//расчет среднего балла
function avgball(sum, key) {
  let  leve={};
  if (!Array.isArray(sum) || sum.length==0) throw "По выбранным параметрам отчета данные отсутствуют!";
      let rowcount=sum.length;  
      leve = sum.reduce((a,b)=>{
      return {
        c1:a.c1+b.c1, 
        c2:a.c2+b.c2,
        c3:a.c3+b.c3,
        c4:a.c4+b.c4,
        c5:a.c5+b.c5,
        c6:a.c6+b.c6,
        c7:a.c7+b.c7,
        c8:a.c8+b.c8,
        c9:a.c9+b.c9,
        c10:a.c10+b.c10,
        c11:a.c11+b.c11,
        c12:a.c12+b.c12,
        c13:a.c13+b.c13
       };
  });
  
  let avg = {
    lpu_id: null,
    docId: '',
    doc_id: null,
    fio: 'ИТОГО',
    c1:roundTo(leve.c1/rowcount, 1),
    c2:roundTo(leve.c2/rowcount, 1),
    c3:roundTo(leve.c3/rowcount, 1),
    c4:roundTo(leve.c4/rowcount, 1),
    c5:roundTo(leve.c5/rowcount, 1),
    c6:roundTo(leve.c6/rowcount, 1),
    c7:roundTo(leve.c7/rowcount, 1),
    c8:roundTo(leve.c8/rowcount, 1),
    c9:roundTo(leve.c9/rowcount, 1),
    c10:roundTo(leve.c10/rowcount, 1),
    c11:roundTo(leve.c11/rowcount, 1),
    c12:roundTo(leve.c12/rowcount, 1),
    c13:roundTo(leve.c13/rowcount, 1)
  }
  return sum.push(avg);
}

function _buildParams(data)
{
  let {lpu_id, doctor_id, rpt28, sdate, edate } = data 
  if(!lpu_id){ throw "Не указан код ЛПО!"};

  let lpu = JSON.parse(lpu_id);
  let doctor = doctor_id ? JSON.parse(doctor_id):null;

  return {
    titleParams: {
      lpu: lpu,
      doctor: doctor ? doctor : null,
      sdate: sdate,
      edate: edate,
      rpt: rpt28
    },
    sqlParams: {
      lpuId: lpu.id,
      docId: (!doctor) ? null : doctor.id,
      sdate: sdate,
      edate: edate,
      flag: 1
    }
  };
}

/**Формирование список пациентов */
async function getPersonList(req, res){
  lRole = getUserRole(req);
  try
  {
      switch(lRole){
          case 1: 
              await PersonList(req, res);
              break;
          case 2:
              throw "У вас нет прав доступа! Обратитесь к администратору сервера";
              break;
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

async function PersonList(req, res){
  params = await _buildReqParams(req.query);

  let sqlResult = await DB.EXEC_ASYNC("rpt_28_revision", params.sqlParams);
  res.render('reports/rpt28/rpt_28_revision', {layout: false, data:sqlResult.recordset, titleData: params.titleParams});
}

async function _buildReqParams(data)
{
  let {lpuId, docId, sdate, edate, row } = data 
  if(row==0){ throw "Неправильно указаны параметры при запросе"};

  let rowname= await getRptRow(Number(row)); 

  return {
      titleParams: {
          sdate: sdate,
          edate: edate,
          rowname: rowname
      },
      sqlParams: {
          lpuId: lpuId,
          docId: docId,
          sdate: sdate,
          edate: edate,
          num: row
      }
  };
}

async function getRptRow(row){
  let sql ='select cast(id as nvarchar) + \'. \' + full_name as rowname from glb_A_eval_result where id=@num'
  let result = await DB.QUERY_ASYNC(sql, {num:row});
  return result.recordset[0].rowname;
}

module.exports ={
  getReport28: getReport,
  resReport28: resReport,
  getPersonList28: getPersonList
 };