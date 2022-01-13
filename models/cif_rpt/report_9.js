/*
* Выписка из амбулаторной карты
*/
const DB = require('../dbConnect');
const xml = require('fast-xml-parser');
const getRole = require('../../helpers/getRoleBackend');
const buildLpuTitle = require('../../helpers/buildLpuTitle');

function getReport(req, res){
    res.render('reports/rpt9/report_9');
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
                throw "For current role don't report_9";
            //  TODO For other roles
            default:
                throw "For current role don't report_9";
        }

    } catch(err){
        res.status(400).send(err);
    };
}

async function _lpu_report(req, res) {
    let params = _buildParams(req.body);
    let sqlResult = await DB.EXEC_ASYNC("rpt_9", params.sqlParams);
    let parsedXml = _xmlParse(sqlResult.recordset[0]);
    let resultData = _buildCases(parsedXml);
    if(!resultData.length){ throw "По выбранным параметрам отчета данные отсутствуют!" }
    res.render('reports/rpt9/rpt_9_result', {layout: false, data: resultData, titleData: params.titleParams});
}

function _buildParams(data) {
    let {sdate, edate, lpu_id, patient_id} = data;
    if(!lpu_id){ throw "Выберите организацию"};
    let lpu = JSON.parse(lpu_id);
    let patient = JSON.parse(patient_id);
    lpu.parent_id = (lpu.id === lpu.parent_id) ? null : lpu.parent_id;
    //if(lpu.parent_id){ throw "Выберите только 'ЦСМ'"};

    return {
        titleParams: {
            sdate: sdate,
            edate: edate,
            code: lpu.code,
            lpu_id: lpu.id,
            lpu_title: buildLpuTitle(lpu),
            csm_name: lpu.parent_name,
            patient: patient
        },
        sqlParams: {
            sdate: sdate,
            edate: edate,
            patient_id: patient.id
        }
    };
}
function _buildCases(rawData){
    let buildedCases = [];
    if(rawData.cases){
        buildedCases = rawData.cases.map((_case) => {
            return {
                a_case: _case,
                visits: _getEmbeds(_case.case_id, rawData.visits || []),
                diagnosis: _getEmbeds(_case.case_id, rawData.diagnosis || []),
                procedures: _getEmbeds(_case.case_id, rawData.procedures || []),
                narrow_specialists: _getEmbeds(_case.case_id, rawData.narrow_specialists || []),
                contraceptions: _getEmbeds(_case.case_id, rawData.contraceptions || []),
                medications: _getEmbeds(_case.case_id, rawData.medications || []),
                a_references: _getEmbeds(_case.case_id, rawData.a_references || []),
                pressures: _getEmbeds(_case.case_id, rawData.pressures || []),
                risks: _getEmbeds(_case.case_id, rawData.risks || []),
                mother_health: _getEmbeds(_case.case_id, rawData.mother_health || []),
                lovz: _getEmbeds(_case.case_id, rawData.lovz || []),
                pressure_reference: _getEmbeds(_case.case_id, rawData.pressure_reference || []),
                chield_health: _getEmbeds(_case.case_id, rawData.chield_health || []),
                observation_chield: _getEmbeds(_case.case_id, rawData.observation_chield || []),
            }
        })
    }
    return buildedCases;
}

function _getEmbeds(case_id, embeds) {
    return embeds.filter((embed) => embed.case_id === case_id);
}

function _xmlParse(data){
    return ['cases', 'visits', 'diagnosis', 'procedures',
        'narrow_specialists', 'contraceptions', 'medications', 'a_references',
        'pressures', 'risks', 'mother_health', 'lovz', 'pressure_reference', 'chield_health',
        'observation_chield'].reduce((acc, col) => {
            return Object.assign(acc, xml.parse(data[col], {arrayMode: true}));
        }, {})
}

module.exports = {
    getReport_9: getReport,
    resReport_9: resReport
};