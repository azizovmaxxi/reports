const {Router}  = require('express');
const router    = Router();
const authCheck  = require('../middleware/auth_check');
const selectTer = require('../models/select_ter');
const getDoctor = require('../models/get_doctor');
const getIcd10 = require('../models/get_icd10');
const getPostCodeList = require('../models/get_post_code');
const getPatient = require('../models/get_patient');
const getVisitType = require('../models/get_vistyp_code');
const getTreeView = require('../models/get_treeview');
const getTraumaType = require('../models/get_traumType');

router.get('/ter_select', authCheck(), selectTer);
router.get('/get_doctor', authCheck(), getDoctor);
router.get('/get_icd10', authCheck(), getIcd10);
router.get('/get_post_code', authCheck(), getPostCodeList);
router.get('/get_patient', authCheck(), getPatient);
router.get('/get_visittype', authCheck(), getVisitType);
router.get('/get_treelpu', authCheck(), getTreeView);
router.get('/get_traumatype', authCheck(), getTraumaType);


module.exports = router;