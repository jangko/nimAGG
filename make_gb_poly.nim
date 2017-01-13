import agg_path_storage

const poly1 = [
  1250.8,1312.4,
  1252.8,1311.6,
  1254,1312,
  1254.8,1313.6,
  1254.8,1314.8,
  1256,1314,
  1257.6,1313.6,
  1258.4,1314.4,
  1260.4,1315.6,
  1261.6,1315.6,
  1262.4,1315.6,
  1263.2,1315.6,
  1264.8,1314.8,
  1266,1315.2,
  1266.8,1315.2,
  1267.2,1312.8,
  1266.8,1311.2,
  1267.6,1310.8,
  1268,1310.4,
  1268,1308.8,
  1268.8,1308.4,
  1270,1307.2,
  1270,1306.8,
  1270,1305.6,
  1270.8,1305.6,
  1271.2,1304,
  1271.2,1304,
  1270.4,1305.6,
  1270.8,1306.4,
  1271.2,1306,
  1271.6,1305.6,
  1272,1304.8,
  1271.6,1303.2,
  1271.2,1302.8,
  1269.2,1302,
  1268.4,1300.4,
  1268.4,1300,
  1269.2,1300.4,
  1270.8,1302.4,
  1272.4,1302,
  1273.2,1302,
  1273.6,1300.4,
  1274.8,1299.2,
  1274.4,1298,
  1275.2,1297.2,
  1274.4,1295.6,
  1274.4,1294.8,
  1274.4,1294.4,
  1274.4,1293.6,
  1273.6,1293.6,
  1273.6,1293.6,
  1273.2,1295.2,
  1273.6,1296.4,
  1273.6,1297.6,
  1273.2,1298,
  1272,1299.2,
  1271.6,1299.2,
  1271.2,1298,
  1272,1298,
  1271.6,1297.6,
  1272,1297.2,
  1272.4,1295.6,
  1270.8,1294,
  1272.8,1294.8,
  1273.2,1293.6,
  1273.6,1293.2,
  1272.8,1292.4,
  1271.6,1291.2,
  1271.2,1291.6,
  1270.4,1292,
  1268.8,1290.8,
  1268.8,1289.2,
  1268.4,1287.6,
  1266,1286.4,
  1265.2,1286.4,
  1265.6,1287.2,
  1264.4,1287.6,
  1264,1287.6,
  1263.2,1288,
  1264,1287.6,
  1264.4,1286.4,
  1264.8,1286.4,
  1265.2,1286,
  1264,1285.2,
  1262,1286.4,
  1261.6,1286.4,
  1261.6,1286.4,
  1261.6,1285.6,
  1261.2,1284,
  1261.6,1283.2,
  1262.8,1283.2,
  1262.8,1281.6,
  1263.2,1280.8,
  1263.2,1280,
  1263.2,1278.4,
  1263.2,1277.6,
  1265.2,1275.6,
  1264.8,1274.4,
  1264,1272.4,
  1264.4,1271.2,
  1265.2,1271.2,
  1265.6,1270.4,
  1264,1271.2,
  1263.6,1270.4,
  1263.2,1270.4,
  1263.6,1269.2,
  1264.4,1268.4,
  1264.4,1266.8,
  1265.2,1264.4,
  1264.8,1261.6,
  1266,1261.2,
  1264.8,1258.4,
  1264,1257.6,
  1263.2,1256,
  1262,1254,
  1262.4,1251.6,
  1260,1247.6,
  1259.6,1246.8,
  1258.8,1247.2,
  1258.8,1246.8,
  1258.8,1246,
  1259.2,1245.6,
  1259.2,1246,
  1259.2,1244.4,
  1260,1243.6,
  1259.2,1242.4,
  1258.8,1242.4,
  1259.2,1242.8,
  1258,1242.4,
  1258,1242.8,
  1257.6,1242.8,
  1256,1242.4,
  1254.4,1244,
  1253.2,1243.2,
  1253.6,1244,
  1253.2,1244,
  1252.8,1244,
  1252.4,1243.6,
  1252.8,1242.8,
  1252.4,1242.8,
  1251.6,1242,
  1250.8,1241.2,
  1250.8,1241.6,
  1251.6,1242,
  1251.6,1242.8,
  1251.2,1243.6,
  1250.8,1244,
  1250.4,1245.2,
  1250.8,1243.6,
  1250.4,1242.8,
  1250.8,1242.8,
  1250,1241.6,
  1248.4,1242,
  1249.2,1243.2,
  1248.4,1243.2,
  1248.4,1243.2,
  1248.4,1242.4,
  1247.6,1242.4,
  1247.2,1242,
  1243.6,1242,
  1242,1241.6,
  1242,1241.2,
  1241.2,1241.6,
  1240.8,1241.2,
  1241.2,1240.4,
  1242,1240,
  1241.6,1240,
  1241.6,1239.2,
  1239.6,1239.2,
  1239.2,1238,
  1238.4,1238,
  1237.6,1238,
  1237.2,1238.8,
  1236.8,1238,
  1236.4,1238,
  1236.8,1236.8,
  1235.2,1236.4,
  1234.4,1235.6,
  1234.8,1235.2,
  1232.4,1234.8,
  1231.2,1235.2,
  1231.2,1235.6,
  1232.4,1236,
  1232.8,1236.8,
  1230.8,1236.4,
  1229.6,1237.2,
  1229.2,1236.4,
  1230,1236.4,
  1230.8,1235.6,
  1230.4,1234.8,
  1230.4,1234.4,
  1229.6,1233.2,
  1228.4,1233.2,
  1228,1232.8,
  1226.8,1233.2,
  1227.2,1232.8,
  1226.4,1232,
  1226.4,1230.8,
  1226,1231.2,
  1224.4,1231.2,
  1224,1229.6,
  1223.2,1229.6,
  1223.2,1230.4,
  1221.6,1230.8,
  1221.2,1229.2,
  1220.4,1229.2,
  1220.4,1229.2,
  1219.6,1230.4,
  1218.4,1229.6,
  1217.6,1230.8,
  1218,1229.6,
  1216.8,1229.6,
  1216.8,1230,
  1216.8,1228.8,
  1216.4,1228.8,
  1216,1228.8,
  1216.4,1228.8,
  1215.6,1229.2,
  1215.6,1228.8,
  1214.8,1228.8,
  1214.4,1228.8,
  1214,1229.2,
  1214.4,1230.4,
  1213.6,1231.6,
  1213.6,1230.8,
  1212.8,1230.4,
  1212,1230.8,
  1212,1229.6,
  1211.6,1229.6,
  1211.2,1229.2,
  1210.8,1229.6,
  1210.8,1230.8,
  1209.6,1229.6,
  1210,1229.6,
  1208.8,1229.2,
  1208.8,1230,
  1208,1229.2,
  1208,1230,
  1208,1230,
  1209.6,1231.2,
  1210.8,1231.2,
  1212.4,1232.8,
  1212,1232.8,
  1208.4,1231.2,
  1208,1231.2,
  1208.8,1232,
  1209.6,1232.8,
  1214,1234,
  1214,1234,
  1214,1234.4,
  1213.6,1234.8,
  1213.2,1235.6,
  1212.8,1236,
  1212.8,1235.6,
  1212,1234,
  1207.2,1233.6,
  1206.8,1233.2,
  1205.2,1233.2,
  1204.8,1233.2,
  1204,1233.2,
  1203.6,1233.2,
  1203.6,1233.2,
  1203.6,1233.6,
  1204.8,1233.2,
  1204.8,1234,
  1204.4,1234.4,
  1204.8,1234.4,
  1206.4,1234.8,
  1206.8,1235.6,
  1206,1235.6,
  1206.4,1236.4,
  1207.6,1236.8,
  1208,1236.4,
  1208,1236.8,
  1209.6,1236.8,
  1208.8,1237.2,
  1210,1238.4,
  1211.2,1238.8,
  1212.4,1238.4,
  1210.4,1238.8,
  1209.2,1238,
  1208.4,1238,
  1208,1237.6,
  1207.6,1238,
  1204,1236.4,
  1204,1236.8,
  1202.8,1237.2,
  1203.2,1237.6,
  1203.6,1238.4,
  1203.2,1239.2,
  1202.4,1238.8,
  1201.2,1238,
  1201.6,1239.6,
  1200.8,1239.6,
  1200.4,1240.4,
  1202.4,1240.8,
  1202.8,1240.4,
  1202.4,1241.2,
  1202,1241.6,
  1202.8,1242,
  1202.8,1242.4,
  1206.8,1243.6,
  1207.6,1244.8,
  1207.6,1244,
  1208,1243.6,
  1208.8,1245.6,
  1209.2,1245.2,
  1210.4,1245.2,
  1208.8,1246,
  1207.6,1246,
  1207.6,1245.2,
  1207.2,1246,
  1204.4,1245.2,
  1203.6,1246,
  1202.8,1246,
  1202.4,1246,
  1203.2,1245.6,
  1202.8,1245.2,
  1201.2,1246,
  1202,1245.6,
  1200.8,1245.6,
  1200,1246,
  1200,1246.4,
  1200,1246.8,
  1200.4,1247.2,
  1200,1247.6,
  1200.8,1247.6,
  1200.8,1247.2,
  1201.6,1247.2,
  1201.6,1248.8,
  1202.4,1248.4,
  1203.2,1249.2,
  1204.8,1249.6,
  1204.8,1248.4,
  1206,1248,
  1206.8,1249.6,
  1206.4,1250,
  1207.2,1250.4,
  1206.8,1249.2,
  1208,1248,
  1209.2,1248,
  1209.6,1248,
  1209.6,1248,
  1210.8,1248,
  1210.8,1248.4,
  1208.8,1248.8,
  1208.8,1250,
  1209.6,1249.6,
  1209.6,1250,
  1210,1251.2,
  1208.4,1252,
  1208.4,1252.4,
  1211.2,1252.8,
  1212.4,1254,
  1213.2,1253.2,
  1212.8,1254,
  1212.4,1254,
  1212.4,1254,
  1212.8,1255.2,
  1213.6,1255.6,
  1215.6,1254.8,
  1215.6,1255.2,
  1217.6,1254.8,
  1221.2,1256,
  1221.2,1255.2,
  1222,1255.2,
  1222.8,1256.4,
  1224.4,1256,
  1224.8,1256.4,
  1226,1256.4,
  1224,1257.2,
  1222.8,1257.2,
  1222.8,1257.6,
  1222.4,1258.8,
  1221.2,1258.4,
  1221.2,1257.6,
  1219.6,1255.6,
  1218.4,1256,
  1217.6,1254.8,
  1217.2,1255.6,
  1218,1256.4,
  1216,1256,
  1214.8,1256.4,
  1214.4,1257.2,
  1214,1257.6,
  1214.4,1256.4,
  1212.4,1256.4,
  1212.4,1255.6,
  1209.6,1256,
  1208.8,1256,
  1210.4,1256.4,
  1212.8,1258.4,
  1214,1259.6,
  1215.2,1259.6,
  1215.2,1260.8,
  1216,1261.2,
  1216,1262.8,
  1217.6,1263.6,
  1217.2,1263.6,
  1215.6,1264,
  1215.6,1264,
  1216.4,1264.4,
  1218.8,1268,
  1220.4,1267.6,
  1221.6,1268,
  1221.2,1268,
  1222.8,1268,
  1221.6,1268,
  1223.2,1268,
  1223.2,1268,
  1223.6,1267.6,
  1223.6,1267.6,
  1223.6,1268.4,
  1224.4,1269.6,
  1223.6,1269.2,
  1222.8,1269.6,
  1223.2,1270,
  1223.6,1270.4,
  1224,1270.4,
  1224,1271.2,
  1222.4,1271.2,
  1220.4,1270.4,
  1216,1270.4,
  1215.2,1270.8,
  1215.2,1272.4,
  1215.2,1272,
  1214.8,1270.8,
  1214.8,1270.8,
  1214.8,1271.6,
  1214.8,1272.4,
  1214.8,1273.2,
  1214.8,1273.2,
  1215.2,1273.2,
  1214.8,1273.6,
  1214.8,1273.2,
  1214.8,1273.6,
  1214.4,1273.6,
  1214.8,1274,
  1214.4,1274,
  1213.6,1273.2,
  1213.2,1272.8,
  1212,1273.6,
  1211.2,1273.6,
  1211.6,1274.4,
  1211.2,1274.4,
  1213.2,1275.2,
  1213.2,1275.2,
  1212.8,1275.2,
  1212.8,1275.6,
  1211.6,1275.6,
  1211.6,1275.6,
  1211.6,1275.6,
  1211.2,1275.6,
  1210.8,1275.6,
  1210.4,1274.8,
  1209.2,1275.6,
  1208.8,1276,
  1208,1275.6,
  1207.6,1276.4,
  1207.2,1276,
  1208,1277.6,
  1209.2,1277.2,
  1208.4,1278,
  1208.4,1278.8,
  1208,1279.2,
  1207.2,1279.6,
  1208.8,1279.2,
  1208.8,1280,
  1210.4,1279.6,
  1209.6,1281.2,
  1212,1281.2,
  1212,1282.4,
  1212.4,1283.6,
  1214,1284.4,
  1215.6,1284,
  1216.4,1284.8,
  1215.6,1284.8,
  1216,1285.2,
  1215.6,1285.2,
  1216,1286.4,
  1216,1286.4,
  1216.4,1286.8,
  1214,1286.8,
  1213.2,1286.8,
  1212,1286.8,
  1212,1286.8,
  1212.4,1288.8,
  1213.6,1288,
  1214,1287.6,
  1214,1287.6,
  1214,1289.2,
  1213.6,1289.2,
  1213.6,1288.4,
  1213.6,1289.2,
  1213.6,1289.6,
  1212.8,1290.4,
  1212.8,1291.2,
  1213.6,1291.6,
  1213.2,1291.6,
  1214,1292.4,
  1213.2,1292.4,
  1213.2,1291.6,
  1212.4,1292,
  1212,1292,
  1212,1292,
  1212.8,1292.8,
  1212.4,1293.2,
  1212.8,1293.6,
  1212.4,1294,
  1212.8,1294.4,
  1212.8,1294.4,
  1211.6,1295.2,
  1211.6,1294.4,
  1211.2,1294.4,
  1211.6,1294,
  1210.8,1294,
  1210.8,1293.6,
  1210.4,1293.2,
  1210.8,1292,
  1210,1292.4,
  1210.4,1295.2,
  1210.8,1295.2,
  1210,1296,
  1210.8,1296,
  1210.8,1296.4,
  1212,1297.6,
  1212.4,1296.4,
  1213.2,1295.6,
  1212.8,1294.8,
  1212,1295.6,
  1212,1295.2,
  1213.6,1294.8,
  1213.6,1296,
  1214,1295.6,
  1214,1296.4,
  1214,1296.4,
  1213.6,1297.2,
  1214,1297.6,
  1215.6,1297.2,
  1218.4,1296.8,
  1219.6,1295.2,
  1220.4,1296.4,
  1221.2,1296,
  1221.6,1295.2,
  1222.4,1294.8,
  1222,1294.4,
  1222.4,1294,
  1222,1293.6,
  1222.8,1293.2,
  1223.2,1292.8,
  1224.4,1295.2,
  1226,1295.2,
  1227.6,1294,
  1228.4,1294.4,
  1228.8,1294.4,
  1229.6,1294,
  1230.8,1292.8,
  1231.6,1292.8,
  1230.8,1294,
  1230.4,1294,
  1231.2,1294.4,
  1232.4,1294.4,
  1231.2,1295.6,
  1231.2,1295.6,
  1232.4,1295.2,
  1232.4,1295.6,
  1231.6,1296,
  1230.4,1295.6,
  1230,1296,
  1231.2,1296.8,
  1231.2,1297.6,
  1231.6,1297.6,
  1232.8,1298,
  1232.4,1298.8,
  1232.8,1299.2,
  1233.2,1298.8,
  1235.2,1298.8,
  1236,1300,
  1236.4,1300.4,
  1237.6,1302.4,
  1238,1302.4,
  1238.4,1302,
  1238,1302.4,
  1236,1302.4,
  1235.6,1302.4,
  1235.6,1302.4,
  1235.6,1302.4,
  1234.8,1302.4,
  1233.2,1300.8,
  1233.2,1302,
  1234.4,1302.4,
  1234.4,1302.4,
  1233.2,1302.4,
  1232.8,1302.4,
  1231.6,1302.4,
  1230.4,1302.4,
  1228.8,1304,
  1229.2,1304.4,
  1228.8,1304.4,
  1229.6,1304.4,
  1229.2,1305.6,
  1230.4,1306.4,
  1234,1305.6,
  1233.2,1306.4,
  1232.4,1306.4,
  1233.2,1306.4,
  1234.4,1305.6,
  1232.4,1307.6,
  1233.2,1307.6,
  1235.6,1307.6,
  1234.8,1308.4,
  1234.8,1308.8,
  1235.6,1308.4,
  1236,1308.4,
  1235.6,1308.8,
  1234.8,1309.2,
  1234.8,1308.8,
  1234,1309.2,
  1234,1310.4,
  1235.2,1310.4,
  1234.8,1310.4,
  1234,1312,
  1234.8,1312,
  1234.8,1312.8,
  1235.6,1312.4,
  1235.6,1313.2,
  1236,1313.2,
  1236,1313.2,
  1236.4,1313.2,
  1236.4,1313.6,
  1236.8,1314.8,
  1238.4,1314.4,
  1238.8,1314.4,
  1238.8,1314.4,
  1238.4,1314,
  1239.6,1314.4,
  1240.4,1314.8,
  1240.4,1316.4,
  1240.8,1316.8,
  1241.6,1316.4,
  1241.6,1315.6,
  1242,1315.6,
  1242.4,1314.8,
  1242,1314.4,
  1242.8,1314.4,
  1242,1314.4,
  1242.8,1314.4,
  1242.8,1314.4,
  1243.2,1315.6,
  1242.4,1315.6,
  1242,1316.8,
  1242.8,1316.8,
  1243.2,1316.8,
  1243.2,1314.8,
  1244,1314.4,
  1244.8,1314,
  1244.8,1313.2,
  1245.2,1314,
  1244.8,1316.4,
  1244.4,1314.4,
  1244.4,1315.2,
  1244.4,1316,
  1243.6,1316.4,
  1244,1316.8,
  1244.4,1316.8,
  1245.2,1317.6,
  1246,1316.8,
  1246,1315.2,
  1246.8,1314,
  1246.8,1314,
  1246.8,1312.8,
  1245.2,1311.6,
  1246,1311.6,
  1246.4,1311.6,
  1245.2,1311.2,
  1244.8,1310,
  1246.4,1311.6,
  1247.6,1312,
  1247.6,1312.4,
  1247.6,1314,
  1246.8,1316,
  1247.6,1316.4,
  1246.8,1317.2,
  1247.6,1317.2,
  1247.6,1317.2,
  1248,1317.2,
  1249.2,1317.6,
  1249.6,1317.6,
  1249.6,1317.2,
  1250.8,1317.2,
  1249.6,1317.6,
  1249.2,1318.4,
  1249.6,1318.4,
  1249.2,1319.2,
  1248.8,1319.6,
  1248.8,1319.6,
  1250.8,1319.2,
  1251.6,1318.4,
  1252.4,1317.6,
  1255.2,1316,
  1255.2,1315.6,
  1252,1314]

const poly2 = [
  1284.0,1396.4,
  1284.4,1395.6,
  1285.2,1395.6,
  1286,1395.2,
  1286,1394.8,
  1286.8,1395.2,
  1286.4,1395.2,
  1286.4,1395.2,
  1286.8,1394.8,
  1288,1394,
  1288,1393.6,
  1286.8,1391.6,
  1288,1392.8,
  1288,1393.6,
  1288.8,1393.6,
  1288.8,1394.8,
  1290,1394.4,
  1290.8,1393.6,
  1291.2,1393.2,
  1290.4,1391.2,
  1291.6,1393.6,
  1292.8,1393.6,
  1293.6,1392.8,
  1293.6,1393.2,
  1293.6,1394,
  1294.4,1393.6,
  1294.8,1394.4,
  1295.6,1394,
  1296,1394.8,
  1296,1394.4,
  1297.6,1394.4,
  1298.8,1394.4,
  1300.4,1394.8,
  1302,1394.8,
  1302,1394.4,
  1302.4,1394.4,
  1303.2,1395.2,
  1304.4,1394.8,
  1304.4,1395.2,
  1303.6,1396.4,
  1304.4,1396.8,
  1304.4,1396.4,
  1306.8,1396,
  1306.8,1395.6,
  1308.4,1396,
  1308.8,1395.6,
  1307.6,1392.8,
  1307.6,1392,
  1308.8,1392,
  1307.6,1389.6,
  1307.2,1389.2,
  1306.4,1387.6,
  1304.4,1387.2,
  1302.8,1384,
  1299.6,1382,
  1298.8,1381.6,
  1298,1380.8,
  1296.4,1379.2,
  1296,1377.6,
  1295.2,1377.6,
  1294.4,1377.2,
  1293.6,1376.8,
  1293.6,1376.4,
  1295.2,1376.4,
  1296.4,1376.8,
  1296.8,1376.8,
  1296.8,1376.4,
  1298,1376.4,
  1298.8,1377.6,
  1299.2,1377.2,
  1298,1375.2,
  1296.4,1373.6,
  1296,1373.6,
  1296,1374,
  1295.2,1374,
  1294,1373.2,
  1292.4,1373.6,
  1292.4,1372.4,
  1290.8,1371.2,
  1290.4,1370.4,
  1293.2,1372.8,
  1295.2,1372.8,
  1295.6,1373.6,
  1296.4,1372.8,
  1294.8,1371.2,
  1294.8,1371.2,
  1294.8,1370.4,
  1294,1370,
  1293.6,1369.6,
  1292.8,1370,
  1293.2,1369.6,
  1292.8,1368.8,
  1293.6,1368.4,
  1294,1368.4,
  1294,1368.4,
  1295.6,1370,
  1295.6,1370.4,
  1295.2,1371.2,
  1298,1371.2,
  1300.4,1372,
  1302,1372.4,
  1302.8,1373.6,
  1304.8,1374.4,
  1308.8,1372.4,
  1310.8,1373.6,
  1311.2,1373.2,
  1312.4,1373.2,
  1316.8,1372.4,
  1317.6,1372.4,
  1318.4,1373.2,
  1319.6,1372.4,
  1320.4,1373.2,
  1322,1373.2,
  1322,1372.4,
  1322.8,1372.8,
  1323.6,1372.4,
  1324,1371.6,
  1324,1370.4,
  1324.8,1368.8,
  1324.4,1368.8,
  1324.8,1368,
  1325.2,1368,
  1321.6,1363.2,
  1320.8,1360.4,
  1321.2,1359.6,
  1319.6,1356,
  1319.6,1354.4,
  1318.4,1352.4,
  1317.2,1351.2,
  1316.8,1351.2,
  1316.8,1349.2,
  1316.8,1349.2,
  1315.6,1348.4,
  1316,1347.6,
  1315.2,1346,
  1312.8,1344.4,
  1312.4,1344,
  1311.6,1344,
  1310.8,1343.6,
  1310,1344,
  1309.2,1343.6,
  1308.4,1343.6,
  1305.6,1342,
  1304.8,1341.6,
  1305.2,1341.2,
  1306.4,1342,
  1310.4,1343.6,
  1311.6,1343.2,
  1311.2,1342,
  1311.2,1341.6,
  1311.2,1341.6,
  1312,1340.4,
  1313.6,1340.4,
  1314.8,1338.8,
  1313.2,1338,
  1311.6,1337.6,
  1310,1337.6,
  1309.6,1337.6,
  1307.2,1335.2,
  1306.8,1334.4,
  1305.2,1334,
  1303.6,1332.8,
  1301.2,1334,
  1299.6,1334,
  1299.6,1332.8,
  1300,1332.8,
  1302,1332.8,
  1304,1332.4,
  1304.4,1332.8,
  1305.2,1332.4,
  1307.2,1332.4,
  1307.6,1331.6,
  1308.8,1331.6,
  1309.6,1332.4,
  1310,1332.4,
  1310.8,1332.8,
  1310.8,1333.6,
  1311.6,1334.4,
  1313.6,1334.4,
  1314.8,1332.8,
  1314.8,1332.8,
  1316,1332.8,
  1318.4,1330.8,
  1320.8,1330.4,
  1320.8,1330.4,
  1321.6,1329.6,
  1322.8,1326.8,
  1324.8,1324.4,
  1325.2,1324.4,
  1325.6,1324,
  1325.6,1323.6,
  1325.6,1323.2,
  1326.8,1323.2,
  1327.2,1323.2,
  1327.6,1321.6,
  1328.4,1320.4,
  1328.4,1319.2,
  1328,1318,
  1328.8,1316.8,
  1328.4,1315.6,
  1329.6,1313.2,
  1329.6,1312.4,
  1330.8,1309.2,
  1331.6,1308,
  1331.6,1307.2,
  1332.8,1303.6,
  1333.2,1302,
  1334.4,1301.6,
  1334,1301.6,
  1334.4,1300.8,
  1334.4,1299.6,
  1334.4,1299.6,
  1334.8,1299.6,
  1334.8,1300,
  1337.2,1299.2,
  1339.6,1298.4,
  1341.6,1297.2,
  1342.8,1296.8,
  1343.6,1296.4,
  1343.6,1295.6,
  1344.8,1294,
  1346,1292,
  1347.2,1291.2,
  1347.6,1289.6,
  1350,1288.8,
  1348.8,1287.6,
  1348,1286.4,
  1349.6,1282.8,
  1351.2,1280,
  1352.8,1277.2,
  1353.2,1275.6,
  1353.2,1275.6,
  1353.2,1276.4,
  1352.8,1276.8,
  1351.6,1277.2,
  1351.2,1276.8,
  1350.4,1276.8,
  1349.6,1277.2,
  1348,1279.2,
  1347.2,1279.6,
  1345.6,1278.4,
  1343.6,1278,
  1342.4,1278.8,
  1341.2,1278,
  1341.6,1277.6,
  1342.8,1278,
  1344,1277.6,
  1344.8,1277.6,
  1347.2,1278.4,
  1348,1278,
  1348.4,1277.2,
  1350.4,1275.6,
  1351.2,1275.6,
  1351.6,1274.4,
  1352.4,1273.2,
  1353.6,1273.2,
  1354,1272.4,
  1354.8,1271.2,
  1356,1267.6,
  1356.8,1266,
  1356.4,1264.4,
  1354,1262,
  1352.8,1259.6,
  1352.4,1259.6,
  1352,1259.2,
  1352.8,1259.2,
  1353.6,1259.2,
  1354,1258.8,
  1355.6,1257.2,
  1357.2,1257.6,
  1357.6,1256.4,
  1357.6,1256.8,
  1358,1258,
  1358.8,1260.8,
  1359.6,1261.6,
  1360.4,1261.2,
  1361.2,1261.6,
  1364,1261.2,
  1364.4,1261.6,
  1364.8,1261.6,
  1365.6,1261.6,
  1366.4,1261.6,
  1365.6,1262,
  1366,1262,
  1366.8,1262,
  1367.6,1261.6,
  1370.4,1261.2,
  1372.4,1259.6,
  1376,1257.2,
  1376.4,1257.2,
  1377.6,1254.4,
  1377.6,1252.8,
  1378,1251.6,
  1377.6,1250,
  1378,1248.8,
  1376.4,1245.6,
  1376.4,1243.6,
  1376,1241.2,
  1374,1240,
  1372.8,1237.2,
  1371.6,1238.8,
  1371.6,1237.6,
  1370,1238,
  1369.6,1237.6,
  1372,1237.6,
  1370.8,1235.2,
  1371.6,1235.2,
  1371.6,1236,
  1372,1235.2,
  1372,1235.2,
  1370.8,1234,
  1369.6,1233.2,
  1368.4,1233.6,
  1367.6,1234,
  1366.8,1234,
  1366,1233.2,
  1365.6,1232.4,
  1363.6,1232,
  1364.4,1231.6,
  1364.8,1231.6,
  1366.4,1232.8,
  1367.2,1232.4,
  1367.2,1231.2,
  1366.8,1229.6,
  1366.4,1229.6,
  1365.2,1229.2,
  1366,1229.6,
  1366.4,1229.2,
  1366.4,1229.6,
  1367.2,1229.6,
  1367.6,1229.2,
  1365.2,1227.2,
  1363.2,1227.2,
  1362,1226,
  1360.4,1226,
  1360,1226,
  1359.2,1225.2,
  1360,1225.2,
  1360.4,1226,
  1361.6,1226,
  1364,1226,
  1364.4,1225.2,
  1364,1224.8,
  1363.2,1224.8,
  1362.4,1224.4,
  1361.6,1224.4,
  1362.4,1223.6,
  1363.2,1223.6,
  1363.6,1223.6,
  1364,1223.6,
  1364,1224.4,
  1364.4,1224,
  1364.4,1224.4,
  1364.4,1225.2,
  1366.8,1224.8,
  1367.6,1223.2,
  1366.8,1223.2,
  1365.2,1222.8,
  1367.2,1222.8,
  1371.6,1224,
  1375.2,1224.4,
  1374.8,1223.2,
  1374,1222,
  1374.8,1220.4,
  1374.4,1218.4,
  1374,1218,
  1372,1217.2,
  1371.6,1217.2,
  1370.4,1216.4,
  1369.2,1215.6,
  1368.4,1214.4,
  1368.8,1212.8,
  1366,1212.8,
  1364.8,1212.4,
  1364,1211.6,
  1359.2,1210,
  1358.4,1208.4,
  1357.6,1207.6,
  1354.4,1208.8,
  1351.2,1210,
  1344,1208.4,
  1343.6,1207.6,
  1343.2,1208.4,
  1343.2,1207.2,
  1342.4,1207.2,
  1340.8,1208.4,
  1341.2,1208.4,
  1340.8,1209.6,
  1340.4,1209.2,
  1340,1209.6,
  1339.6,1209.6,
  1340,1209.2,
  1340.4,1208.4,
  1338.8,1208.4,
  1339.2,1208.4,
  1339.2,1209.6,
  1338.4,1209.2,
  1338.4,1208,
  1338,1208,
  1337.6,1208,
  1338,1209.2,
  1338,1210,
  1336.4,1209.2,
  1337.2,1208.8,
  1336.8,1208,
  1334.4,1209.2,
  1333.6,1210.4,
  1332,1211.2,
  1332,1210.8,
  1333.2,1210.4,
  1334.4,1208.8,
  1333.6,1208,
  1332.4,1208,
  1331.2,1206.8,
  1329.2,1206.8,
  1328,1206.8,
  1328.4,1206.8,
  1328.4,1206.8,
  1327.2,1206.8,
  1326.4,1206.8,
  1325.2,1205.6,
  1325.2,1206.8,
  1323.6,1206.8,
  1323.2,1205.6,
  1323.6,1206,
  1323.6,1205.2,
  1325.2,1205.2,
  1325.2,1204.4,
  1325.6,1204.4,
  1325.2,1204,
  1324.8,1203.2,
  1323.6,1203.2,
  1323.2,1203.2,
  1321.2,1204,
  1318,1204,
  1317.6,1203.6,
  1317.2,1202.8,
  1318,1202,
  1317.2,1201.2,
  1317.2,1202.4,
  1314.8,1204.4,
  1312.4,1206,
  1310.8,1206.4,
  1309.6,1205.6,
  1307.6,1205.6,
  1306,1205.6,
  1303.6,1203.2,
  1302.8,1203.6,
  1302,1205.2,
  1302.4,1203.2,
  1301.2,1201.2,
  1301.6,1200,
  1300.4,1199.2,
  1300.8,1198.8,
  1301.6,1198,
  1301.2,1198,
  1300.8,1197.6,
  1300,1197.2,
  1300,1196.8,
  1299.2,1196.4,
  1299.2,1195.6,
  1299.2,1194.4,
  1298,1194,
  1297.2,1194.4,
  1297.2,1194.4,
  1296.4,1194.4,
  1295.6,1196,
  1294.4,1196.8,
  1292.8,1196.8,
  1291.6,1196.8,
  1291.6,1197.6,
  1290.4,1198,
  1290.4,1198,
  1291.2,1197.6,
  1290.8,1196.8,
  1290,1196.8,
  1289.6,1198,
  1288.8,1198,
  1287.2,1198,
  1286.4,1197.2,
  1283.6,1197.2,
  1283.2,1197.2,
  1283.2,1197.6,
  1282,1197.2,
  1281.2,1194.8,
  1280,1195.2,
  1279.6,1194.4,
  1278.8,1194.4,
  1278.8,1192.8,
  1278,1192.8,
  1278.4,1192.8,
  1278,1192.8,
  1278,1195.2,
  1277.6,1195.2,
  1277.2,1194.4,
  1277.6,1193.6,
  1277.2,1192.8,
  1277.6,1192.8,
  1277.2,1192.8,
  1277.2,1192,
  1276.4,1192,
  1277.2,1191.6,
  1277.2,1190.8,
  1276.8,1190,
  1275.6,1190,
  1275.2,1188.8,
  1274.4,1190,
  1274,1191.2,
  1273.2,1191.6,
  1270.8,1193.2,
  1270,1192.8,
  1270,1192,
  1269.6,1191.2,
  1268,1190.8,
  1267.2,1191.6,
  1267.6,1192,
  1267.2,1193.6,
  1268,1193.2,
  1270,1195.2,
  1271.6,1194.4,
  1272.4,1195.2,
  1273.2,1195.2,
  1274,1196.4,
  1274.8,1197.6,
  1276,1198.4,
  1276,1199.2,
  1277.6,1199.6,
  1278.4,1200.8,
  1278,1201.6,
  1278.4,1202.4,
  1278.8,1202.4,
  1279.6,1203.2,
  1279.6,1202.8,
  1280,1203.6,
  1282,1203.6,
  1282,1205.2,
  1283.2,1206.4,
  1283.6,1207.2,
  1285.6,1208,
  1285.6,1210.8,
  1286.4,1213.2,
  1286.8,1213.2,
  1288.8,1212.8,
  1289.2,1212.8,
  1290.4,1213.6,
  1291.2,1214.4,
  1290,1216.4,
  1290.4,1216.4,
  1290.4,1216.8,
  1290.8,1216.8,
  1297.2,1218.8,
  1300,1218.4,
  1300.4,1218.4,
  1302.4,1217.6,
  1302.8,1217.2,
  1304.4,1217.2,
  1306,1217.6,
  1308,1217.6,
  1308.8,1218.4,
  1308.8,1218.8,
  1308.8,1220,
  1309.2,1220,
  1309.6,1222,
  1310.4,1222.8,
  1312.4,1224.4,
  1313.2,1224.8,
  1316.8,1230,
  1318,1230.8,
  1318,1231.6,
  1318,1230.8,
  1316.8,1230.8,
  1313.2,1227.2,
  1310.8,1226,
  1309.6,1225.6,
  1309.6,1225.6,
  1309.6,1225.6,
  1308.8,1225.6,
  1307.2,1224.4,
  1307.2,1223.6,
  1306.4,1223.6,
  1306.4,1222.8,
  1305.2,1222.4,
  1302.8,1222.4,
  1300.8,1222.8,
  1299.2,1224.4,
  1298.4,1224.4,
  1297.2,1225.6,
  1296.4,1228,
  1294,1228,
  1294,1227.6,
  1294,1226,
  1291.6,1226,
  1291.6,1226,
  1290.8,1225.6,
  1289.6,1226,
  1289.6,1227.2,
  1290,1227.6,
  1290.4,1227.6,
  1290.8,1227.6,
  1292.4,1228,
  1292.8,1228.8,
  1293.2,1229.2,
  1292,1228.8,
  1291.2,1229.6,
  1289.6,1229.2,
  1289.6,1229.2,
  1288.4,1230,
  1288.4,1230.8,
  1289.6,1230,
  1288.8,1231.2,
  1288.8,1232,
  1288.4,1231.2,
  1287.6,1231.6,
  1287.6,1230.8,
  1284.4,1230.4,
  1283.6,1229.2,
  1282.8,1229.2,
  1282.4,1228.4,
  1281.2,1228,
  1280,1227.6,
  1278.4,1228.4,
  1278.4,1229.2,
  1277.6,1229.2,
  1277.6,1229.6,
  1278.4,1229.2,
  1278.8,1229.6,
  1278.8,1229.6,
  1279.6,1229.6,
  1281.2,1230,
  1279.6,1230.4,
  1276.8,1230.4,
  1276.8,1229.6,
  1276,1230.4,
  1275.6,1231.2,
  1276.4,1231.2,
  1276.8,1232,
  1278,1232,
  1277.6,1234,
  1276.4,1234,
  1274.4,1234.4,
  1274.8,1236,
  1276,1235.6,
  1276.4,1236,
  1278,1236.8,
  1278,1237.6,
  1279.6,1237.2,
  1280,1237.2,
  1280.8,1237.2,
  1280.8,1238,
  1281.2,1237.2,
  1282,1237.6,
  1282,1238.4,
  1282.8,1238.8,
  1283.6,1240,
  1284,1240,
  1284,1240.8,
  1286.8,1240.4,
  1288.8,1242.4,
  1289.6,1242.4,
  1290.8,1242.8,
  1292,1244.8,
  1292.8,1246.4,
  1293.6,1249.6,
  1294.4,1250,
  1295.2,1250.4,
  1293.6,1250.4,
  1292.4,1251.6,
  1293.6,1254,
  1294.4,1255.2,
  1293.6,1254.4,
  1293.2,1255.2,
  1292.4,1255.6,
  1292,1256.4,
  1292.8,1257.6,
  1292,1258.4,
  1288.8,1258.4,
  1288,1257.6,
  1287.6,1256.8,
  1287.6,1256.4,
  1286.8,1255.2,
  1285.6,1256.8,
  1285.2,1256.4,
  1284,1256.8,
  1283.6,1256,
  1283.6,1256.8,
  1284,1257.6,
  1285.6,1258.8,
  1286.8,1259.6,
  1289.2,1261.6,
  1289.2,1263.6,
  1290,1263.6,
  1290,1263.6,
  1292,1266.4,
  1292.8,1266.8,
  1293.6,1266.8,
  1296.4,1267.6,
  1296.8,1267.6,
  1296.4,1268.8,
  1297.6,1268.4,
  1298.4,1267.6,
  1300,1268,
  1303.6,1269.2,
  1304.8,1269.2,
  1304.8,1268.8,
  1307.6,1266.4,
  1308,1267.6,
  1306,1270,
  1306.4,1270,
  1308.4,1271.2,
  1308.8,1270.4,
  1310,1268.4,
  1311.2,1268,
  1312.4,1268,
  1312.8,1268.8,
  1312,1268.8,
  1310.4,1268.8,
  1309.6,1270.4,
  1307.6,1273.2,
  1309.2,1277.2,
  1311.2,1278.8,
  1308.4,1278.8,
  1308,1280.4,
  1308.4,1282.8,
  1310.4,1283.6,
  1310.8,1283.2,
  1311.2,1284.4,
  1310.8,1284.4,
  1310.8,1284.8,
  1310.4,1284.8,
  1310,1285.6,
  1310.8,1286.8,
  1311.6,1286.8,
  1311.6,1287.6,
  1311.2,1289.2,
  1311.6,1290,
  1310.8,1290,
  1310,1288.4,
  1309.6,1288.4,
  1308.4,1290,
  1307.6,1287.6,
  1306.8,1286.4,
  1307.2,1286.4,
  1305.6,1287.6,
  1305.6,1288.4,
  1305.6,1288.8,
  1306,1288.8,
  1306.4,1291.2,
  1305.6,1289.6,
  1304.4,1289.6,
  1303.2,1291.6,
  1303.2,1292.8,
  1300,1297.2,
  1300.8,1299.2,
  1301.2,1300.4,
  1302,1302,
  1302.8,1303.2,
  1302.8,1304,
  1303.6,1305.6,
  1304.4,1306,
  1304.4,1305.6,
  1305.2,1305.6,
  1305.6,1306,
  1305.2,1306,
  1305.2,1306.8,
  1306,1307.6,
  1307.6,1306.8,
  1308.4,1307.2,
  1308.4,1307.6,
  1308,1307.6,
  1308,1308,
  1308.8,1308,
  1308.8,1308.4,
  1307.2,1308.4,
  1305.6,1308,
  1303.2,1308,
  1302.8,1308,
  1302,1308,
  1301.6,1308,
  1301.2,1308,
  1301.2,1308,
  1301.2,1305.6,
  1300.8,1305.6,
  1299.2,1306,
  1298.4,1305.6,
  1298,1306,
  1297.6,1305.6,
  1297.6,1306,
  1298,1306,
  1297.2,1305.2,
  1297.6,1304.8,
  1295.6,1303.2,
  1294.4,1303.2,
  1294.4,1304.8,
  1294,1303.6,
  1293.2,1303.6,
  1292,1304.8,
  1292.4,1306,
  1291.6,1304.8,
  1290.4,1306,
  1290,1306.4,
  1289.6,1307.2,
  1289.6,1306,
  1289.2,1306.4,
  1289.2,1304.8,
  1290.4,1304.4,
  1290,1303.6,
  1290.4,1301.6,
  1290,1301.6,
  1288,1301.6,
  1286.8,1303.6,
  1284.4,1304.8,
  1284,1306,
  1283.6,1306.4,
  1282.4,1305.2,
  1281.6,1304.4,
  1282.4,1301.6,
  1282.8,1301.6,
  1283.2,1301.2,
  1283.6,1300.4,
  1283.2,1300.4,
  1282,1301.2,
  1282,1302.4,
  1279.6,1306,
  1278.8,1308,
  1279.2,1309.6,
  1280,1309.6,
  1280.4,1309.6,
  1280.8,1307.6,
  1281.6,1306.4,
  1281.6,1307.2,
  1280.8,1309.6,
  1280.8,1310,
  1281.2,1312.4,
  1283.6,1314.8,
  1284,1317.2,
  1284.8,1317.6,
  1285.2,1319.2,
  1286.8,1319.6,
  1286.8,1320.4,
  1286.4,1321.6,
  1286,1321.6,
  1286.4,1322,
  1286,1323.2,
  1284.4,1324,
  1284.4,1324.4,
  1283.2,1326,
  1284,1326.8,
  1283.6,1328.4,
  1283.2,1330.8,
  1283.6,1331.2,
  1284.8,1332.4,
  1285.6,1330.8,
  1288.8,1330.8,
  1286.8,1332,
  1285.2,1333.2,
  1284.4,1334.4,
  1284.8,1333.2,
  1285.2,1332.8,
  1284.8,1332.8,
  1284,1332.8,
  1283.6,1334.4,
  1284.8,1335.6,
  1284,1335.2,
  1284,1336,
  1283.6,1336.4,
  1283.2,1335.6,
  1284,1334.8,
  1283.6,1333.2,
  1282.8,1333.2,
  1283.2,1332.8,
  1282,1330,
  1281.2,1330,
  1281.2,1331.2,
  1280.8,1332.8,
  1280.8,1330.8,
  1279.6,1331.2,
  1279.6,1332.8,
  1279.6,1332.8,
  1279.2,1330.8,
  1278.8,1330.8,
  1279.2,1329.2,
  1277.6,1330,
  1277.2,1330.8,
  1277.6,1333.2,
  1278.4,1334.8,
  1279.6,1335.6,
  1279.6,1336,
  1281.2,1336.8,
  1281.6,1338,
  1283.2,1339.6,
  1282,1338.8,
  1281.2,1338.8,
  1280.8,1337.2,
  1278.8,1336,
  1277.2,1333.2,
  1276.4,1333.2,
  1276,1333.2,
  1276,1332,
  1276.4,1331.2,
  1276.4,1330,
  1278,1328.4,
  1277.6,1327.6,
  1276.8,1327.2,
  1276,1326,
  1275.6,1324.8,
  1275.2,1323.6,
  1275.6,1323.2,
  1275.2,1322.8,
  1275.2,1322,
  1274,1319.6,
  1273.6,1319.6,
  1274,1319.6,
  1274.8,1318.4,
  1274,1317.2,
  1272,1316.4,
  1270.8,1316.8,
  1270.8,1319.2,
  1272,1319.6,
  1272.4,1322,
  1272,1323.2,
  1272.8,1324.4,
  1272.8,1325.2,
  1275.6,1329.2,
  1274,1328,
  1272.8,1328.4,
  1272.8,1329.6,
  1274.4,1331.6,
  1272.8,1330.8,
  1272.8,1331.6,
  1274.8,1334.4,
  1274,1333.6,
  1272.8,1331.6,
  1272.4,1331.6,
  1272.8,1333.2,
  1273.6,1333.6,
  1273.6,1334.8,
  1274.4,1335.2,
  1275.2,1335.2,
  1274.8,1336,
  1275.2,1338,
  1274.4,1336,
  1274,1336.4,
  1274.8,1338,
  1274.4,1339.2,
  1274.4,1341.2,
  1275.2,1341.2,
  1276.4,1344,
  1279.2,1343.6,
  1278,1344.8,
  1277.2,1344.4,
  1276.8,1344.8,
  1276.8,1344.4,
  1276.4,1344.8,
  1276.8,1345.6,
  1277.6,1345.2,
  1278.4,1346,
  1279.2,1346.4,
  1277.6,1346,
  1277.2,1346.4,
  1278,1348.4,
  1278.4,1348.8,
  1278.4,1348.8,
  1279.6,1349.2,
  1280.8,1349.2,
  1281.6,1349.6,
  1280.8,1349.2,
  1279.2,1349.6,
  1281.2,1352.8,
  1280,1351.6,
  1279.6,1351.6,
  1278.8,1350,
  1278,1349.6,
  1277.6,1349.6,
  1276,1348,
  1275.2,1346,
  1273.2,1345.2,
  1273.2,1345.2,
  1272.4,1346,
  1272.4,1346,
  1270.4,1346.8,
  1269.6,1347.6,
  1269.2,1348.8,
  1270,1349.2,
  1270.8,1349.2,
  1272.8,1350,
  1274,1349.6,
  1275.2,1349.2,
  1273.6,1349.6,
  1272.4,1350,
  1271.6,1349.6,
  1270.8,1350,
  1266.8,1350,
  1266.4,1350.4,
  1267.6,1351.6,
  1269.2,1351.6,
  1270,1352,
  1270.8,1351.6,
  1271.2,1351.2,
  1271.2,1352,
  1271.2,1351.6,
  1272.4,1352,
  1272.4,1352,
  1271.6,1353.2,
  1271.6,1353.6,
  1272.8,1353.6,
  1273.2,1353.6,
  1274,1354,
  1273.6,1354,
  1273.2,1353.6,
  1272.8,1354,
  1273.2,1354.8,
  1270.8,1355.2,
  1271.2,1354.8,
  1272,1354.8,
  1271.6,1355.2,
  1272,1357.2,
  1273.2,1357.6,
  1273.2,1357.2,
  1274,1356.4,
  1276,1356.8,
  1274.8,1356.8,
  1274,1357.2,
  1274,1357.6,
  1274,1358.4,
  1272.8,1358.8,
  1272.8,1359.2,
  1273.6,1360,
  1274.4,1360,
  1276,1358.8,
  1277.2,1359.6,
  1275.6,1359.2,
  1275.6,1360,
  1274.4,1361.2,
  1274,1361.6,
  1274.8,1361.6,
  1274.8,1362.4,
  1274.8,1362.8,
  1274.8,1363.6,
  1276,1363.6,
  1276.4,1363.6,
  1277.6,1362.4,
  1278,1362.8,
  1277.2,1362.8,
  1276.4,1364,
  1274,1364,
  1273.6,1364,
  1274.4,1365.2,
  1276.4,1366.4,
  1277.2,1367.6,
  1276,1366.4,
  1275.2,1365.2,
  1274.8,1366.4,
  1275.2,1366.4,
  1275.2,1366.8,
  1273.2,1365.6,
  1272.4,1365.6,
  1272.4,1366.8,
  1272.8,1367.2,
  1272.4,1367.2,
  1272.8,1367.6,
  1272,1368,
  1272,1369.2,
  1272.8,1370.8,
  1273.2,1370.8,
  1273.6,1370,
  1274,1370.4,
  1274.8,1369.2,
  1274.8,1369.6,
  1275.2,1369.2,
  1276.4,1370,
  1275.6,1370,
  1274.8,1370.4,
  1274.4,1370.8,
  1274.4,1370.8,
  1274,1371.6,
  1274,1372.4,
  1272.8,1372.4,
  1273.2,1374.4,
  1274.4,1374.4,
  1274.4,1374.4,
  1273.6,1374.4,
  1272.8,1375.2,
  1273.2,1376,
  1272.8,1377.6,
  1274.4,1378,
  1274.8,1377.6,
  1274.8,1376,
  1275.2,1375.2,
  1275.6,1376,
  1276,1376,
  1276,1377.6,
  1275.2,1378,
  1275.6,1379.6,
  1276,1379.2,
  1276.4,1379.6,
  1276.4,1378,
  1277.6,1378,
  1278,1379.2,
  1280.8,1377.6,
  1280.4,1378,
  1278.8,1379.6,
  1278.4,1380,
  1278.8,1380,
  1279.6,1378.8,
  1280.4,1379.2,
  1281.6,1378,
  1282.4,1377.2,
  1282.4,1377.6,
  1280.8,1379.2,
  1281.2,1379.6,
  1281.2,1379.6,
  1280,1380.4,
  1279.2,1381.2,
  1278.4,1382.4,
  1278.4,1382.4,
  1278,1382.8,
  1278,1383.6,
  1279.2,1382.8,
  1279.2,1382.8,
  1280.4,1382.8,
  1280.8,1382.8,
  1280,1384,
  1280.4,1384,
  1280,1384.4,
  1280.4,1384.4,
  1280,1384.8,
  1280,1384.8,
  1279.2,1385.6,
  1279.6,1385.6,
  1278.8,1386.8,
  1278.8,1387.6,
  1280,1386,
  1281.2,1387.2,
  1281.6,1386.4,
  1282.4,1387.2,
  1284.4,1386.4,
  1284,1386.8,
  1284.4,1387.2,
  1283.2,1387.2,
  1282,1388,
  1282.4,1388.4,
  1282,1388.4,
  1281.6,1388.8,
  1282.4,1390.4,
  1283.6,1390,
  1283.2,1390.4,
  1282.8,1390.8,
  1283.2,1390.8,
  1282.8,1391.2,
  1283.6,1391.6,
  1284.4,1391.2,
  1284,1392,
  1282.4,1392.8,
  1282.4,1393.2,
  1283.6,1393.6]

proc loadPoly(ps: var PathStorage, p: openArray[float64]) =
  ps.moveTo(p[0], p[1])
  let len = p.len div 2
  for i in countup(1, len, 2):
    ps.lineTo(p[i], p[i+1])
  ps.closePolygon()

proc makeGBPoly*(ps: var PathStorage) =
  ps.removeAll()
  ps.loadPoly(poly1)
  ps.loadPoly(poly2)