const {DB} = require('../config/config');
const SQL  = require('mssql');
const POOL = new SQL.ConnectionPool({
  dialect: DB.DIALECT,
  user: DB.USER,
  password: DB.PASSWORD,
  server: DB.HOST,
  database: DB.CATALOG,
  port: DB.PORT,
  pool: {...DB.POOL},
  retry: DB.RETRY.TIMEOUT,
  requestTimeout: DB.REQUEST.TIMEOUT,
  commandTimeout: DB.COMMAND.TIMEOUT,
  encryption: DB.ENCRYPTION,
  connectionTimeout: DB.connectionTimeout || 300000
});

const RETRY=DB.RETRY.TIMEOUT;

var ERROR=false;

POOL.connect(function(e){
  ERROR=e;
});

const QUERY=function(q,p,f){
  const s=POOL.request();
  if(p&&Object.keys(p)&&Object.keys(p).length)for(var i in p)s.input(i,p[i]);
  s.query(q,function(e,r){
    if(e&&f)f(e);
    else if(!e&&f) f(e,r);
  });
};

const EXEC=function(q,p,f){
  const s=POOL.request();
  if(p&&Object.keys(p)&&Object.keys(p).length){
    for(var i in p){
      if(p[i]&&Object.keys(p[i])&&Object.keys(p[i]).length&&p[i].output&&p[i].default)s.output(i,p[i].type,p[i].default);
      else if(p[i]&&Object.keys(p[i])&&Object.keys(p[i]).length&&p[i].output)s.output(i,p[i].type);
      else s.input(i,p[i]);
    }
  }
  s.execute(q,function(e,r){
    if(e&&f)f(e);
    else if(!e&&f) f(e,r);
  });
};

const QUERY_ASYNC=function(q,p){
  const s=POOL.request();
  if(p&&Object.keys(p)&&Object.keys(p).length)for(var i in p)s.input(i,p[i]);
  return s.query(q);
};

const EXEC_ASYNC=function(q,p){
  const s=POOL.request();
  if(p&&Object.keys(p)&&Object.keys(p).length){
    for(var i in p){
      if(p[i]&&Object.keys(p[i])&&Object.keys(p[i]).length&&p[i].output&&p[i].default)s.output(i,p[i].type,p[i].default);
      else if(p[i]&&Object.keys(p[i])&&Object.keys(p[i]).length&&p[i].output)s.output(i,p[i].type);
      else s.input(i,p[i]);
    }
  }
  return s.execute(q);
};

module.exports={
  QUERY:function(q,p,f){
    if(!POOL._connected&&!POOL._connecting)POOL.connect(function(e){
      ERROR=e;
      if(!e)QUERY(q,p,f);
      else if(f)f(e);
    });
    else if(POOL._connecting)setTimeout(function(){module.exports.QUERY(q,p,f);},RETRY);
    else QUERY(q,p,f);
  },
  EXEC:function(q,p,f){
    if(!POOL._connected&&!POOL._connecting)POOL.connect(function(e){
      ERROR=e;
      if(!e)EXEC(q,p,f);
      else if(f)f(e);
    });
    else if(POOL._connecting)setTimeout(function(){module.exports.EXEC(q,p,f);},RETRY);
    else EXEC(q,p,f);
  },
  QUERY_ASYNC:function(q,p){
    if(!POOL._connected&&!POOL._connecting)POOL.connect(function(e){
      ERROR=e;
      if(e){throw e};
      return QUERY_ASYNC(q,p);
    });
    else if(POOL._connecting)setTimeout(function(){module.exports.QUERY_ASYNC(q,p);},RETRY);
    else return QUERY_ASYNC(q,p);
  },
  EXEC_ASYNC:function(q,p){
    if(!POOL._connected&&!POOL._connecting)POOL.connect(function(e){
      ERROR=e;
      if(e){throw e}
      return EXEC_ASYNC(q,p);
    });
    else if(POOL._connecting)setTimeout(function(){module.exports.EXEC_ASYNC(q,p);},RETRY);
    else return EXEC_ASYNC(q,p);
  }
};
