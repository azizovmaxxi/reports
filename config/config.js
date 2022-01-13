module.exports = {
  APP: {
    PORT: 3030,
    SECRET_KEY: "secretKey"
  },
  DB: {
    DIALECT: "mssql",
    USER: "sa",
    PASSWORD: "HTtt89jtreS",
    HOST: "192.168.26.12",
    PORT: 1434,
    CATALOG: "person",
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
