CREATE TABLE zipcode (
  publicCode char(5) NOT NULL,
  oldCode char(5) NOT NULL,
  code char(7) NOT NULL,
  prefectureKana varchar(10),
  cityKana varchar(100),
  townKana varchar(100),
  prefecture varchar(10),
  city varchar(200),
  town varchar(200),
  flgMultiCode tinyint(1),
  flgKoazaBanchi tinyint(1),
  flgChome tinyint(1),
  flgMultiTown tinyint(1),
  updateState tinyint(1),
  updateReason tinyint(1),
  PRIMARY KEY (code)
);

LOAD DATA LOCAL INFILE '/docker-entrypoint-initdb.d/KEN_ALL.CSV' IGNORE INTO TABLE zipcode FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"';
