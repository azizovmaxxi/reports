const {Router} = require('express');
const router   = Router();
const authCheck = require('../middleware/auth_check');

router.get('/', authCheck(), function(req, res){
	res.render('index', {});
});

module.exports = router;
