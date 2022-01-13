const {Router} = require('express');
const router   = Router();
const authCheck = require('../middleware/auth_check');
const sideBarMenu = require('../models/sidebar_menu');
const passport = require('passport');
const redis        = require('redis');
const redisClient  = redis.createClient();

router.get("/logout", authCheck(), function(req, res) {
  let { passport } = req.session

  req.session.destroy(function(err) {
    if (err) throw new Error(err);
    redisClient.del(passport.user);
    req.logout();
    res.redirect('/login');
  });
});

router.get("/login", function(req, res){
  res.render("auth/login", {layout: false, authMessage: req.flash('authError')});
});

router.post('/login', function(req, res, next) {
  passport.authenticate('local', async function(err, user, info) {
    if (err) { return next(err); }
    if (!user) {
      req.flash('authError', 'Неверный логин или пароль!');
      return res.redirect('/login');
    }

    req.logIn(user, async function(err) {
      if (err) { return next(err); }
    
      req.session.sidebarMenu = await sideBarMenu();
      return res.redirect('/');
    });
  })(req, res, next);
});

module.exports = router;