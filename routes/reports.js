/*
 *   Определение маршрутов
*/
const {Router} = require('express');
const router   =  Router();
const authCheck = require('../middleware/auth_check');
const {getReport1, getPersonList1, resReport1} = require('../models/cif_rpt/report_1');
const {getReport28, getPersonList28, resReport28} = require('../models/cif_rpt/report_28');
const {getReport_2_1, resReport_2_1} = require('../models/cif_rpt/report_2_1');
const {getReport_2_2, resReport_2_2} = require('../models/cif_rpt/report_2_2');
const {getReport_2_3, resReport_2_3} = require('../models/cif_rpt/report_2_3');
const {getReport_2_4, resReport_2_4} = require('../models/cif_rpt/report_2_4');
const {getReport_4, resReport_4} = require('../models/cif_rpt/report_4');
const {getReport_6, resReport_6} = require('../models/cif_rpt/report_6');
const {getReport_15, resReport_15} = require('../models/cif_rpt/report_15');
const {getReport_16, resReport_16} = require('../models/cif_rpt/report_16');
const {getReport_17, resReport_17} = require('../models/cif_rpt/report_17');
const {getReport_21, resReport_21} = require('../models/cif_rpt/report_21');
const {getReport_23, resReport_23} = require('../models/cif_rpt/report_23');
const {getReport_26, resReport_26} = require('../models/cif_rpt/report_26');
const {getReport_12, resReport_12} = require('../models/cif_rpt/report_12');
const {getReport_2_5, resReport_2_5} = require('../models/cif_rpt/report_2_5');
const {getReport_2_6, resReport_2_6} = require('../models/cif_rpt/report_2_6');
const {getReport_3, resReport_3} = require('../models/cif_rpt/report_3');
const {getReport_2_8, resReport_2_8} = require('../models/cif_rpt/report_2_8');
const {getReport_25, resReport_25} = require('../models/cif_rpt/report_25');
const {getReport_29, resReport_29} = require('../models/cif_rpt/report_29');
const {getReport_11, resReport_11} = require('../models/cif_rpt/report_11');
const {getReport_10, resReport_10} = require('../models/cif_rpt/report_10');
const {getReport_18, resReport_18} = require('../models/cif_rpt/report_18');
const {getReport_24, resReport_24} = require('../models/cif_rpt/report_24');
const {getReport_13, resReport_13} = require('../models/cif_rpt/report_13');
const {getReport_9, resReport_9} = require('../models/cif_rpt/report_9');
const {getReport_22, resReport_22} = require('../models/cif_rpt/report_22');
const {getReport_30, resReport_30} = require('../models/cif_rpt/report_30');
const {getReport_31, resReport_31} = require('../models/cif_rpt/report_31');
const {getReport_32, resReport_32} = require('../models/cif_rpt/report_32');
const {getReport_33, resReport_33} = require('../models/cif_rpt/report_33');
const {getReport_19, resReport_19} = require('../models/cif_rpt/report_19');
const {getReport_34, resReport_34} = require('../models/cif_rpt/report_34');
const {getReport_2_7, resReport_2_7} = require('../models/cif_rpt/report_2_7');
const {getReport_43, resReport_43} = require('../models/cif_rpt/report_43');
const {getReport_44, resReport_44} = require('../models/cif_rpt/report_44');
const {getReport_45, resReport_45} = require('../models/cif_rpt/report_45');
const {getReport_46, resReport_46} = require('../models/cif_rpt/report_46');
const {getReport_47, resReport_47} = require('../models/cif_rpt/report_47');
const {getReport_48, resReport_48} = require('../models/cif_rpt/report_48');
const {getReport_49, resReport_49} = require('../models/cif_rpt/report_49');
const {getReport_50, resReport_50} = require('../models/cif_rpt/report_50');
const {getReport_51, resReport_51} = require('../models/cif_rpt/report_51');
const {getReport_52, resReport_52} = require('../models/cif_rpt/report_52');
const {getReport_53, resReport_53} = require('../models/cif_rpt/report_53');
const {getReport_54, resReport_54} = require('../models/cif_rpt/report_54');
const {getReport_55, resReport_55} = require('../models/cif_rpt/report_55');
const {getReport_56, resReport_56} = require('../models/cif_rpt/report_56');
const {getReport_57, resReport_57} = require('../models/cif_rpt/report_57');
const {getReport_58, resReport_58} = require('../models/cif_rpt/report_58');
const {getReport_59, resReport_59} = require('../models/cif_rpt/report_59');
const {getReport_60, resReport_60} = require('../models/cif_rpt/report_60');

// Сестринский КИФ
const {getMReport_1, resMReport_1} = require('../models/m_cif_rpt/report_1');
const {getMReport_2, resMReport_2} = require('../models/m_cif_rpt/report_2');
const {getMReport_3, resMReport_3} = require('../models/m_cif_rpt/report_3');
const {getMReport_4, resMReport_4} = require('../models/m_cif_rpt/report_4');
const {getMReport_5, resMReport_5} = require('../models/m_cif_rpt/report_5');
const {getMReport_6, resMReport_6} = require('../models/m_cif_rpt/report_6');
const {getMReport_7, resMReport_7} = require('../models/m_cif_rpt/report_7');
const {getMReport_8, resMReport_8} = require('../models/m_cif_rpt/report_8');
const {getMReport_9, resMReport_9} = require('../models/m_cif_rpt/report_9');
const {getMReport_10, resMReport_10} = require('../models/m_cif_rpt/report_10');
const {getMReport_11, resMReport_11} = require('../models/m_cif_rpt/report_11');


//Форма 12.Заболеваемость населения
router.get('/report_1', authCheck(), getReport1);
router.post('/report_1', authCheck(), resReport1);

//Карта оценки результатов работы семейного врача
router.get('/report_28', authCheck(), getReport28);
router.post('/report_28', authCheck(), resReport28);

//Штаты, деятельность ГСВ
router.get('/report_2_1', authCheck(), getReport_2_1);
router.post('/report_2_1', authCheck(), resReport_2_1);

//Штаты, деятельность ГСВ по специальностям
router.get('/report_2_2', authCheck(), getReport_2_2);
router.post('/report_2_2', authCheck(), resReport_2_2);

//Штаты, деятельность ГСВ по должностям
router.get('/report_2_3', authCheck(), getReport_2_3);
router.post('/report_2_3', authCheck(), resReport_2_3);

//Помощь при неотложных состояниях
router.get('/report_2_4', authCheck(), getReport_2_4);
router.post('/report_2_4', authCheck(), resReport_2_4);

//Поиск по КИФам
router.get('/report_4', authCheck(), getReport_4);
router.post('/report_4', authCheck(), resReport_4);

router.get('/report_6', authCheck(), getReport_6);
router.post('/report_6', authCheck(), resReport_6);

//Количество впервые выявленных больных с ГБ
router.get('/report_15', authCheck(), getReport_15);
router.post('/report_15', authCheck(), resReport_15);

//Количество больных с ГБ перенесших инсульт
router.get('/report_16', authCheck(), getReport_16);
router.post('/report_16', authCheck(), resReport_16);

//Кол-во больных с ГБ перенесших острый инфаркт миокарда
router.get('/report_17', authCheck(), getReport_17);
router.post('/report_17', authCheck(), resReport_17);

//Доля лиц с выявленными факторами риска
router.get('/report_21', authCheck(), getReport_21);
router.post('/report_21', authCheck(), resReport_21);

//Взят под наблюдение с ГБ
router.get('/report_23', authCheck(), getReport_23);
router.post('/report_23', authCheck(), resReport_23);

//Кол-во пац-ов с раз. уровнями риск факторов по Номограмме
router.get('/report_26', authCheck(), getReport_26);
router.post('/report_26', authCheck(), resReport_26);

//Процент КИФ  с заполненным факторами риска
router.get('/report_12', authCheck(), getReport_12);
router.post('/report_12', authCheck(), resReport_12);

//Использование контрацептивов
router.get('/report_2_5', authCheck(), getReport_2_5);
router.post('/report_2_5', authCheck(), resReport_2_5);

//Травмы
router.get('/report_2_6', authCheck(), getReport_2_6);
router.post('/report_2_6', authCheck(), resReport_2_6);

//Послеродовая помощь
router.get('/report_3', authCheck(), getReport_3);
router.post('/report_3', authCheck(), resReport_3);

//Показатели смешанного приема врачей ГСВ
router.get('/report_2_8', authCheck(), getReport_2_8);
router.post('/report_2_8', authCheck(), resReport_2_8);

/*Ревизия данных */
router.get('/report_revision', authCheck(), getPersonList1);

//Кол-во посещений в ЦСМ больных с ГБ по поводу повышения АД.
router.get('/report_25', authCheck(), getReport_25);
router.post('/report_25', authCheck(), resReport_25);

//Процент пациентов обследованных на холестерин и глюкозу
router.get('/report_29', authCheck(), getReport_29);
router.post('/report_29', authCheck(), resReport_29);

//Курение
router.get('/report_11', authCheck(), getReport_11);
router.post('/report_11', authCheck(), resReport_11);

//Сведение о результатах АД (мах.мин)
router.get('/report_10', authCheck(), getReport_10);
router.post('/report_10', authCheck(), resReport_10);

//Медицинские наблюдение за больными ГБ
router.get('/report_18', authCheck(), getReport_18);
router.post('/report_18', authCheck(), resReport_18);

//Количество пациентов с высоким риском ФР
router.get('/report_24', authCheck(), getReport_24);
router.post('/report_24', authCheck(), resReport_24);

router.get('/report_13', authCheck(), getReport_13);
router.post('/report_13', authCheck(), resReport_13);

//Выписка из амбулаторной карты
router.get('/report_9', authCheck(), getReport_9);
router.post('/report_9', authCheck(), resReport_9);

//Количество новых зарегистрировааных больных с ГБ с повторным визитом в ЦСМ
router.get('/report_22', authCheck(), getReport_22);
router.post('/report_22', authCheck(), resReport_22);

//Процент женщин у которых проведен осмотр шейка матки
router.get('/report_30', authCheck(), getReport_30);
router.post('/report_30', authCheck(), resReport_30);

//Процент женщин у которых выявлены изменения шейки матки
router.get('/report_31', authCheck(), getReport_31);
router.post('/report_31', authCheck(), resReport_31);

//Процент женщин у которых проведен осмотр молочных желез
router.get('/report_32', authCheck(), getReport_32);
router.post('/report_32', authCheck(), resReport_32);

//Процент женщин у которых выявлены изменения молочной железы
router.get('/report_33', authCheck(), getReport_33);
router.post('/report_33', authCheck(), resReport_33);

//Доля лиц взр. населения 18 лет и старше, которым измерялось АД
router.get('/report_19', authCheck(), getReport_19);
router.post('/report_19', authCheck(), resReport_19);

/*Ревизия данных */
router.get('/report28_revision', authCheck(), getPersonList28);

//Посещение населения старше 18 лет в организации здравоохранения ПМСП
router.get('/report_34', authCheck(), getReport_34);
router.post('/report_34', authCheck(), resReport_34);

//Структура умерших
router.get('/report_2_7', authCheck(), getReport_2_7);
router.post('/report_2_7', authCheck(), resReport_2_7);

//Посещения к врачам, ведущим амбулаторно-поликлинический прием
router.get('/report_43', authCheck(), getReport_43);
router.post('/report_43', authCheck(), resReport_43);

router.get('/report_44', authCheck(), getReport_44);
router.post('/report_44', authCheck(), resReport_44);

router.get('/report_45', authCheck(), getReport_45);
router.post('/report_45', authCheck(), resReport_45);

router.get('/report_46', authCheck(), getReport_46);
router.post('/report_46', authCheck(), resReport_46);

router.get('/report_47', authCheck(), getReport_47);
router.post('/report_47', authCheck(), resReport_47);

router.get('/report_48', authCheck(), getReport_48);
router.post('/report_48', authCheck(), resReport_48);

router.get('/report_49', authCheck(), getReport_49);
router.post('/report_49', authCheck(), resReport_49);

router.get('/report_50', authCheck(), getReport_50);
router.post('/report_50', authCheck(), resReport_50);

router.get('/report_51', authCheck(), getReport_51);
router.post('/report_51', authCheck(), resReport_51);

router.get('/report_52', authCheck(), getReport_52);
router.post('/report_52', authCheck(), resReport_52);

router.get('/report_53', authCheck(), getReport_53);
router.post('/report_53', authCheck(), resReport_53);

router.get('/report_54', authCheck(), getReport_54);
router.post('/report_54', authCheck(), resReport_54);

router.get('/report_55', authCheck(), getReport_55);
router.post('/report_55', authCheck(), resReport_55);

router.get('/report_56', authCheck(), getReport_56);
router.post('/report_56', authCheck(), resReport_56);

router.get('/report_57', authCheck(), getReport_57);
router.post('/report_57', authCheck(), resReport_57);

// Население по возрастам и по полу
router.get('/report_58', authCheck(), getReport_58);
router.post('/report_58', authCheck(), resReport_58);

// Возрастная структура женщин репродуктивного возраста 
// медико-социальной группы риска
router.get('/report_59', authCheck(), getReport_59);
router.post('/report_59', authCheck(), resReport_59);

// Доля женщин, закончивших беременность (%)
router.get('/report_60', authCheck(), getReport_60);
router.post('/report_60', authCheck(), resReport_60);

// ** Сестринский КИФ ** \\

//1.Штаты специалистов сестринского дела
router.get('/m_report_1', authCheck(), getMReport_1);
router.post('/m_report_1', authCheck(), resMReport_1);

//Характеристика обслуживаемого населения ФАП/ЦСМ/ЦОВП/ГСВ
router.get('/m_report_2', authCheck(), getMReport_2);
router.post('/m_report_2', authCheck(), resMReport_2);

//Наблюдение по НИЗ(стар. 18 лет, кол. пациентов)
router.get('/m_report_3', authCheck(), getMReport_3);
router.post('/m_report_3', authCheck(), resMReport_3);

//Раздел амбулторно-поликлинические посещения и охрана здоровья матери ти ребенка
router.get('/m_report_4', authCheck(), getMReport_4);
router.post('/m_report_4', authCheck(), resMReport_4);

//Охрана здоровья детского населения
router.get('/m_report_5', authCheck(), getMReport_5);
router.post('/m_report_5', authCheck(), resMReport_5);

//Использование контрацептивных средств(КС)
router.get('/m_report_6', authCheck(), getMReport_6);
router.post('/m_report_6', authCheck(), resMReport_6);

//Число случаев насилия
router.get('/m_report_7', authCheck(), getMReport_7);
router.post('/m_report_7', authCheck(), resMReport_7);

//Исключение туберкулеза
router.get('/m_report_8', authCheck(), getMReport_8);
router.post('/m_report_8', authCheck(), resMReport_8);

//Процедуры, манипуляции, анализы, выполненные специалистом сестирнского дела
router.get('/m_report_9', authCheck(), getMReport_9);
router.post('/m_report_9', authCheck(), resMReport_9);

//Направлен к врачу
router.get('/m_report_10', authCheck(), getMReport_10);
router.post('/m_report_10', authCheck(), resMReport_10);

//Назначен повторный визит
router.get('/m_report_11', authCheck(), getMReport_11);
router.post('/m_report_11', authCheck(), resMReport_11);




module.exports = router;