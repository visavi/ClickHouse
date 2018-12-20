SET send_logs_level = 'none';

DROP TABLE IF EXISTS test.compression_codec;

CREATE TABLE test.compression_codec(id UInt64 CODEC(LZ4), data String CODEC(ZSTD), ddd Date CODEC(NONE), somenum Float64 CODEC(ZSTD(2))) ENGINE = MergeTree() ORDER BY tuple();

INSERT INTO test.compression_codec VALUES(1, 'hello', toDate('2018-12-14'), 1.1);
INSERT INTO test.compression_codec VALUES(2, 'world', toDate('2018-12-15'), 2.2);
INSERT INTO test.compression_codec VALUES(3, '!', toDate('2018-12-16'), 3.3);

SELECT * FROM test.compression_codec ORDER BY id;

OPTIMIZE TABLE test.compression_codec FINAL;

INSERT INTO test.compression_codec VALUES(2, '', toDate('2018-12-13'), 4.4);

SELECT count(*) FROM test.compression_codec WHERE id = 2 GROUP BY id;

DROP TABLE IF EXISTS test.compression_codec;

DROP TABLE IF EXISTS test.bad_codec;
DROP TABLE IF EXISTS test.params_when_no_params;
DROP TABLE IF EXISTS test.params_zstd;
DROP TABLE IF EXISTS test.too_many_params;
DROP TABLE IF EXISTS test.codec_multiple_direct_specification;

CREATE TABLE test.bad_codec(id UInt64 CODEC(adssadads)) ENGINE = MergeTree() order by tuple(); -- { serverError 430 }
CREATE TABLE test.too_many_params(id UInt64 CODEC(ZSTD(2,3,4,5))) ENGINE = MergeTree() order by tuple(); -- { serverError 429 }
CREATE TABLE test.params_when_no_params(id UInt64 CODEC(LZ4(1))) ENGINE = MergeTree() ORDER BY tuple(); -- { serverError 378 }
CREATE TABLE test.params_zstd(id UInt64 CODEC(ZSTD(33))) ENGINE = MergeTree() ORDER BY tuple(); -- { serverError 431 }
CREATE TABLE test.codec_multiple_direct_specification(id UInt64 CODEC(MULTIPLE(LZ4, ZSTD))) ENGINE = MergeTree() ORDER BY tuple(); -- { serverError 430 }

DROP TABLE IF EXISTS test.bad_codec;
DROP TABLE IF EXISTS test.params_when_no_params;
DROP TABLE IF EXISTS test.params_zstd;
DROP TABLE IF EXISTS test.too_many_params;
DROP TABLE IF EXISTS test.codec_multiple_direct_specification;

DROP TABLE IF EXISTS test.compression_codec_multiple;

CREATE TABLE test.compression_codec_multiple (
    id UInt64 CODEC(LZ4, ZSTD, NONE),
    data String CODEC(ZSTD(2), NONE, LZ4, LZ4),
    ddd Date CODEC(NONE, NONE, NONE, LZ4, ZSTD),
    somenum Float64 CODEC(LZ4, LZ4, ZSTD(2), ZSTD(3), ZSTD)
) ENGINE = MergeTree() ORDER BY tuple();

INSERT INTO test.compression_codec_multiple VALUES (1, 'world', toDate('2018-10-05'), 1.1), (2, 'hello', toDate('2018-10-01'), 2.2), (3, 'buy', toDate('2018-10-11'), 3.3);

SELECT * FROM test.compression_codec_multiple ORDER BY id;

INSERT INTO test.compression_codec_multiple select modulo(number, 100), toString(number), toDate('2018-12-01'), 5.5 * number FROM system.numbers limit 10000;

SELECT count(*) FROM test.compression_codec_multiple;

SELECT count(distinct data) FROM test.compression_codec_multiple;

SELECT floor(sum(somenum), 1) FROM test.compression_codec_multiple;

TRUNCATE TABLE test.compression_codec_multiple;

INSERT INTO test.compression_codec_multiple select modulo(number, 100), toString(number), toDate('2018-12-01'), 5.5 * number FROM system.numbers limit 10000;

SELECT sum(cityHash64(*)) FROM test.compression_codec_multiple;

DROP TABLE IF EXISTS test.compression_codec_multiple_more_types;

CREATE TABLE test.compression_codec_multiple_more_types (
    id Decimal128(13) CODEC(ZSTD, LZ4, ZSTD, ZSTD),
    data FixedString(12) CODEC(ZSTD, ZSTD, NONE, NONE, NONE),
    ddd Nested (age UInt8, Name String) CODEC(LZ4, NONE, NONE, NONE, ZSTD)
) ENGINE = MergeTree() ORDER BY tuple();

INSERT INTO test.compression_codec_multiple_more_types VALUES(1.5555555555555, 'hello world!', [77], ['John']);
INSERT INTO test.compression_codec_multiple_more_types VALUES(7.1, 'xxxxxxxxxxxx', [127], ['Henry']);

SELECT * FROM test.compression_codec_multiple_more_types order by id;

DROP TABLE IF EXISTS test.compression_codec_multiple_with_key;

CREATE TABLE test.compression_codec_multiple_with_key (
    somedate Date CODEC(ZSTD, ZSTD, ZSTD(12)),
    id UInt64 CODEC(LZ4, ZSTD, NONE),
    data String CODEC(ZSTD(2), NONE, LZ4, LZ4)
) ENGINE = MergeTree() PARTITION BY somedate ORDER BY id SETTINGS index_granularity = 2;


INSERT INTO test.compression_codec_multiple_with_key VALUES(toDate('2018-10-12'), 100000, 'hello'), (toDate('2018-10-12'), 100002, 'world'), (toDate('2018-10-12'), 1111, '!');

SELECT data FROM test.compression_codec_multiple_with_key WHERE id BETWEEN 3 AND 1112;

INSERT INTO test.compression_codec_multiple_with_key SELECT toDate('2018-10-12'), number, toString(number) FROM system.numbers LIMIT 1000;

SELECT COUNT(DISTINCT data) FROM test.compression_codec_multiple_with_key WHERE id < 222;

DROP TABLE IF EXISTS test.compression_codec_multiple_with_key;