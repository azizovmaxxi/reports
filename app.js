const path         = require('path');
const logger       = require('morgan');
const express      = require('express');
const createError  = require('http-errors');
const cookieParser = require('cookie-parser');
const expressHbs   = require("express-handlebars");
const session      = require('express-session');
const flash        = require('connect-flash');

const redis        = require('redis');
const redisClient  = redis.createClient();
const RedisStore   = require('connect-redis')(session);
const passport     = require('passport');
require('./authenticate/auth_init');
const currentUser  = require('./middleware/current_user');
const sideBarMenu  = require('./middleware/sidebarMenu');
const requestMethod = require('./middleware/requestMethod');

//locals
const indexRoutes  = require('./routes/index');
const reportRoutes = require('./routes/reports');
const authRoutes   = require('./routes/auth');
const apiRoutes    = require('./routes/api');
const config       = require('./config/config');
const hbsHelpers   = require('./helpers/index')

var app = express();

// устанавливаем настройки для файлов layout
app.engine("hbs", expressHbs({
    layoutsDir: "views/layouts",
    defaultLayout: "layout",
    extname: "hbs",
    helpers: { ...hbsHelpers }
  }
));

//set static directory
app.use(express.static(path.join(__dirname, 'public')));

app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'hbs');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(flash());

app.use(session({
  store: new RedisStore({
    client: redisClient,
    host: config.REDIS_STORE.HOST,
    port: config.REDIS_STORE.PORT,
    logErrors: true,
    prefix: "cif",
  }),
  cookie: {
    maxAge: 10 * 60 * 60 * 1000,
    httpOnly: false,
  },
  secret: config.APP.SECRET_KEY,
  resave: false,
  saveUninitialized: false
}));

app.use(passport.initialize());
app.use(passport.session()); //TODO set session
app.use(currentUser);
app.use(sideBarMenu);

//routes
app.use(requestMethod);
app.use('/', indexRoutes);
app.use('/report', reportRoutes);
app.use(authRoutes);
app.use(apiRoutes);

app.use('*',function(req, res){
  res.redirect('/')
});
// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});


module.exports = app;
