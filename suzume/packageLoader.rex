let std = require("std");

let pmInfo = require(format("${str}/share/info.rex", rexPkgRoot));
let log = require(format("${str}/share/log.rex", rexPkgRoot));
let api = require(format("${str}/backend/api.rex", rexPkgRoot));

func rexModInit() {
    log.log(log.logLevel.info, pmInfo.getSuzumeInfo());

    let pm = api.packageManager({
        globalPM: null,
        pkgRoot: null
    });
    pm.open();
    
    pm.close();
    return 0;
}