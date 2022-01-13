/*
* Обработка отчета 4. Поиск по кифам
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');
const moment = require('moment');

function getReport(req, res){
    res.render('reports/rpt4/rpt_4');
}

async function resReport(req, res){
    try
    {
        //Вытаскивать отчет в зависимости от роли, т.к. отчет по разному вычисляется для роли
        switch(getRole(req.user)){
            case 'lpu':
                await _lpu_report(req, res);
                break;
            case 'republic':
                throw "For current role don't report_4";
            //  TODO For other roles
            default:
                throw "For current role don't report_4";
        }

    } catch(err){
        res.status(400).send(err);
    };
}

async function _lpu_report(req, res) {
    let params = _buildParams(req.body);
    let sqlResult = await DB.EXEC_ASYNC("rpt_4", params.sqlParams);

    res.render('reports/rpt4/rpt_4_result', {layout: false, data: sqlResult.recordset, titleData: params.titleParams});
}

function _buildParams(data) {
    let {sdate, edate, lpu_id, doctor_id, post_code} = data;
    let expectedParams = ["first_name", "last_name", "mid_name", "sex_id", "birthday_start",
                          "birthday_end", "icd10_start", "icd10_end", "is_f_life", "is_final",
                          "visit", "accept_gipotenz", "control_ad", "percen", "cervix", "cervix_change",
                          "breast", "breast_change", "is_registered", "got_acid", "iodine", "one_preg",
                          "two_preg", "positive_result", "course_treatmedt", "hiv", "hiv_result", "tested_anemia",
                          "jda", "rh0", "doctor_visit", "protein_urine", "sowing_urine", "ad", "gravidogramm",
                          "vistyp_code", "traumtype", "emergency", "hospid"];
    if(!lpu_id){ throw "Выберите организацию"};
    if(!sdate || !edate){ throw "Необходимо выставить диапазон даты 1-го посещения"};
    let lpu = JSON.parse(lpu_id);
    let doctor = doctor_id ? JSON.parse(doctor_id) : null;
    let postcode = post_code ? JSON.parse(post_code) : null;

    let rawParams = expectedParams.reduce((resultParams, value) => {
        if(data[value]){resultParams[value] = data[value]}
        return resultParams;
    }, {});

    return {
        titleParams: {
            sdate: sdate,
            edate: edate,
            code: lpu.code,
            lpu_id: lpu.id,
            lpu_title: buildLpuTitle(lpu),
            csm_name: lpu.parent_name,
            doctor_name: doctor ? doctor.name : null,
            post_code: postcode ? `${postcode.name}(${postcode.code})` : null,
            ..._buildTitleParams(rawParams)
        },
        sqlParams: {
            sdate: sdate,
            edate: edate,
            lpu_id: lpu.id,
            lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
            doctor_id: doctor ? doctor.id : null,
            post_code: postcode ? postcode.code : null,
           ...rawParams
        }
    };
}

function _buildTitleParams(rawParams={}){
    let params = Object.assign({}, rawParams);
    if(params['birthday_start'] && params['birthday_end']){
        params['birthday'] = ` | Дата рождения: с ${moment(params['birthday_start']).format('DD.MM.YYYY')} по ${moment(params['birthday_end']).format('DD.MM.YYYY')}`;
    } else if(params['birthday_start'] || params['birthday_end']){
        params['birthday'] = ` | Дата рождения: ${moment(params['birthday_start']).format('DD.MM.YYYY') || moment(params['birthday_end']).format('DD.MM.YYYY')}`;
    }

    if(params['icd10_start'] && params['icd10_end']){
        params['icd10'] = ` | МКБ-10: с ${params['icd10_start']} по ${params['icd10_end']}`;
    } else if(params['icd10_start'] || params['icd10_end']){
        params['icd10'] = ` | МКБ-10: ${params['icd10_start'] || params['icd10_end']}`;
    }

    ['is_final', 'is_f_life', 'accept_gipotenz', 'control_ad', 'cervix', 'cervix_change',
     'breast', 'breast_change', 'got_acid', 'iodine', 'one_preg', 'two_preg', 'positive_result',
     'course_treatmedt', 'hiv', 'hiv_result', 'tested_anemia', 'jda', 'rh0', 'protein_urine',
     'sowing_urine', 'ad', 'gravidogramm'
    ].forEach((field)=>{
        if(params[field]){ params[field] = params[field] == '1' ? 'Да': 'Нет' }
    });

    if(params['percen']) {
        switch (params['percen']) {
            case "1":
                params['percen'] = '<10%';
                break;
            case "2":
                params['percen'] = '10<20%';
                break;
            case "3":
                params['percen'] = '20<30%';
                break;
            case "4":
                params['percen'] = '30<39%';
                break;
            case "5":
                params['percen'] = 'более 40%';
                break;
        }
    }

    if(params['doctor_visit']) {
        params['doctor_visit'] = params['doctor_visit'] == '1' ? 'Врачом' : 'Мед. сестрой'
    }

    if (params['emergency']) {
        params['emergency'] = params['emergency'] == '1'?'Неотложная помощь':'';
    }

    if (params['hospid']) {
        params['hospid'] = params['hospid'] == '1'?'Госпитализация':'';
    }
    console.log(params);
    return params;
}

module.exports = {
    getReport_4: getReport,
    resReport_4: resReport
};