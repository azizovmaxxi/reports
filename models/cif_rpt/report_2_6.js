/*
* Травмы
*/
const DB = require('../dbConnect');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('reports/rpt2_6/report_2_6');
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
                throw "For current role don't report_2_6";
            //  TODO For other roles
            default:
                throw "For current role don't report_2_6";
        }

    } catch(err){
        res.status(400).send(err);
    };
}

async function _lpu_report(req, res) {
    let params = _buildParams(req.body);
    let sqlResult = await DB.EXEC_ASYNC("rpt_2_6", params.sqlParams);

    res.render('reports/rpt2_6/rpt_2_6_result', {layout: false, data: sqlResult.recordset, titleData: params.titleParams});
}

function _buildParams(data) {
    let {sdate, edate, lpu_id, is_f_life, age, sex_id} = data;
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
            is_f_life: is_f_life=='1' ? 'Впервые в жизни' : null,
            age: _age_title(age)
        },
        sqlParams: {
            sdate: sdate,
            edate: edate,
            lpu_id: lpu.id,
            lpu_parent_id: (lpu.id === lpu.parent_id) ? null : lpu.parent_id,
            is_f_life: is_f_life ? is_f_life : null,
            age: age ? age : null,
            sex_id: sex_id ? sex_id : null
        }
    };
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
        default: return null
    }
}

module.exports = {
    getReport_2_6: getReport,
    resReport_2_6: resReport
};