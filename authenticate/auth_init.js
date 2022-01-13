const passport       = require('passport');
const LocalStrategy  = require('passport-local').Strategy;
const passwordHasher = require('aspnet-identity-pw');
const User           = require('../models/user');
const redis        = require('redis');
const redisClient  = redis.createClient();

passport.serializeUser(function(user, done) {
  done(null, user.UserName)
});

passport.deserializeUser((userName, done) => {
    //const user = await User.findOne({where: {UserName: userName}, include:  [ 'roles' ]});
    redisClient.get(userName, (err, user) => {
      if (user) {
        done(null, JSON.parse(user));
      } else {
        done(null, false);
      }
    });
  });

passport.use(new LocalStrategy(
  async function(username, password, done) {
    const user = await User.findOne({where: {UserName: username}, include:  [ 'roles' ]});
    let err = null; //TODO return error

    if(err){ return done(err) }
    if(!user){ return done(null, false) }

    if(!passwordHasher.validatePassword(password, user.PasswordHash)){
      return done(null, false)
    }

    redisClient.set(user.UserName, JSON.stringify({
      id: user.id,
      UserName: user.UserName,
      GsvId: user.GsvId,
      roles: user.roles
    }));
    return done(null, user);
  })
);


module.exports = passport;