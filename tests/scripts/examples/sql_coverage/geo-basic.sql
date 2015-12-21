-- Run the basic-template against DDL with all Geo types (point & polygon)
<configure-for-geo.sql>
<basic-template.sql>

-- Test inserting points & polygons, via the pointFromText & pointFromText functions
INSERT INTO _table VALUES (100, null,                                 null,                                 null);
INSERT INTO _table VALUES (101, null,                                 pointFromText('POINT(  0.0   0.0 )'), null);
INSERT INTO _table VALUES (102, pointFromText('POINT( -1.0   1.0 )'), null,                                 null);
INSERT INTO _table VALUES (103, pointFromText('POINT(  0.0   1.0 )'), pointFromText('POINT(  0.0   1.0 )'), null);
INSERT INTO _table VALUES (104, pointFromText('POINT( -1.0   0.0 )'), pointFromText('POINT(  0.0   0.0 )'), null);
INSERT INTO _table VALUES (105, pointFromText('POINT(  0.0   0.0 )'), pointFromText('POINT(  1.0   1.0 )'), null);
INSERT INTO _table VALUES (106, pointFromText('POINT(  1.0   1.0 )'), pointFromText('POINT(  2.0   2.0 )'), null);
INSERT INTO _table VALUES (107, pointFromText('POINT(-71.06 42.36)'), pointFromText('POINT(  0.0   0.0 )'), null);
INSERT INTO _table VALUES (201, null,                                 null,                                 polygonFromText('POLYGON((0 0, 0.01 0, 0.01 0.01, 0 0.01, 0 0))') );
INSERT INTO _table VALUES (202, pointFromText('POINT(-71.0 42.0)'),   null,                                 polygonFromText('POLYGON((0 0, 0.01 0, 0.01 0.01, 0 0.01, 0 0))') );
INSERT INTO _table VALUES (203, pointFromText('POINT(0.005 0.005)'),  null,                                 polygonFromText('POLYGON((0 0, 0.01 0, 0.01 0.01, 0 0.01, 0 0))') );
INSERT INTO _table VALUES (204, pointFromText('POINT(  0.0  0.0 )'),  pointFromText('POINT(-71.06 42.36)'), polygonFromText('POLYGON((-1 -1, 1 -1, 1    1,   -1 1,  -1 -1))') );
INSERT INTO _table VALUES (205, pointFromText('POINT( -2.5  2.5 )'),  pointFromText('POINT(-71.06 42.36)'), polygonFromText('POLYGON((-3  2,-2  2,-2    3,   -3 3,  -3  2))') );

-- Test points and the asText, LONGITUDE & LATITUDE functions
SELECT @star from _table G01;
SELECT ID,    asText(PT1),                   asText(PT2)                from _table G02;
SELECT ID, LONGITUDE(PT1), LATITUDE(PT1), LONGITUDE(PT2), LATITUDE(PT2) from _table G03;
SELECT ID, LONGITUDE(PT1), LATITUDE(PT1), LONGITUDE(PT2), LATITUDE(PT2) from _table G04 WHERE LONGITUDE(PT1) < 0 AND LATITUDE(PT1) > 0;

-- Test the DISTANCE function, with points & polygons
SELECT ID, DISTANCE(PT1,  PT2  ) from _table G11;
SELECT ID, DISTANCE(PT1,  PT2  ) from _table G12 WHERE DISTANCE(PT1,  PT2  ) > 200000;
SELECT ID, DISTANCE(PT1,  POLY1) from _table G13;
SELECT ID, DISTANCE(PT1,  POLY1) from _table G14 WHERE DISTANCE(PT1,  POLY1) > 200000;
SELECT ID, DISTANCE(POLY1,PT1  ) from _table G15;
SELECT ID, DISTANCE(POLY1,PT1  ) from _table G16 WHERE DISTANCE(POLY1,PT2  ) > 200000;
-- DISTANCE between two polygons is not yet supported
SELECT ID, DISTANCE(POLY1,POLY1) from _table G17;
SELECT ID, DISTANCE(POLY1,POLY1) from _table G18 WHERE DISTANCE(POLY1,POLY1) < 200000;
SELECT A.ID AID, B.ID BID, DISTANCE(A.POLY1,B.POLY1) G19DIST FROM _table A JOIN _table B ON A.ID <= B.ID;

-- Test polygons and the asText, AREA & CENTROID functions (also using LONGITUDE, LATITUDE)
SELECT ID,              asText(POLY1) from _table G21;
SELECT ID, AREA(POLY1)                from _table G22;
SELECT ID, AREA(POLY1)                from _table G23 WHERE AREA(POLY1) > 2000000;
SELECT ID, AREA(POLY1), asText(POLY1) from _table G24;
SELECT ID, AREA(POLY1), asText(POLY1) from _table G25 WHERE AREA(POLY1) > 2000000;
SELECT ID, asText(CENTROID(POLY1))    from _table G26;
SELECT ID, LONGITUDE(PT1), LATITUDE(PT1), LONGITUDE(PT2), LATITUDE(PT2), LONGITUDE(CENTROID(POLY1)), LATITUDE(CENTROID(POLY1)) from _table G27;

-- Test the CONTAINS function, with polygons & points (also using LONGITUDE, LATITUDE, asText)
SELECT ID,                      LONGITUDE(PT1), LATITUDE(PT1) from _table G31 WHERE CONTAINS(POLY1,PT1);
SELECT ID,                      LONGITUDE(PT1), LATITUDE(PT1) from _table G32 WHERE NOT CONTAINS(POLY1,PT1);
SELECT ID,                      asText(PT1),    asText(POLY1) from _table G33 WHERE CONTAINS(POLY1,PT1);
SELECT ID,                      asText(PT1),    asText(POLY1) from _table G34 WHERE NOT CONTAINS(POLY1,PT1);
-- These won't work until CONTAINS (& boolean return values) is supported in the initial SELECT clause
SELECT ID, CONTAINS(POLY1,PT1), LONGITUDE(PT1), LATITUDE(PT1) from _table G35;
SELECT ID, CONTAINS(POLY1,PT1), asText(PT1),    asText(POLY1) from _table G36;