module.exports = {
  APP: {
    PORT: 3030,
    SECRET_KEY: "secretKey"
  },
  DB: {
    DIALECT: "mssql",
    USER: "0",
    PASSWORD: "0",
    HOST: "0",
    PORT: 0,
    CATALOG: "0",
    ENCRYPTION: true,
    REQUEST: {
        TIMEOUT:600000
    },
    COMMAND: {
      TIMEOUT:600000
    },
    RETRY: {
        TIMEOUT: 10
    },
    POOL: {
      MAX: 5,
      MIN: 0,
      ACQUIRE: 30000,
      IDLE: 10000
    },
    connectionTimeout: 300000
  },
	REDIS_STORE: {
		HOST: "localhost",
		PORT: 6379
	}
};
