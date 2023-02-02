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
    if (rexArgs.length() == 0) {
        log.log(log.logLevel.error, "Invalid arguments");
        return null;
    }
    
    if (rexArgs[0] == "i") {
        let localPM = api.packageManager({
            globalPM: pm,
            pkgRoot: "."
        });
        for (let i = 1;i < rexArgs.length();++i) {
            let arg = rexArgs[i].split('@');
            localPM.installFromRemote(arg[0], arg[1]);
        }
    } else if (rexArgs[0] == "r") {
        let localPM = api.packageManager({
            globalPM: pm,
            pkgRoot: "."
        });
        for (let i = 1;i < rexArgs.length();++i) {
            let arg = rexArgs[i].split('@');
            localPM.remove(arg[0], arg[1]);
        }
    } else if (rexArgs[0] == "ig") {
        // throw 114514;
        for (let i = 1;i < rexArgs.length();++i) {
            let arg = rexArgs[i].split('@');
            pm.installFromRemote(arg[0], arg[1]);
        }
    } else if (rexArgs[0] == "rg") {
        for (let i = 1;i < rexArgs.length();++i) {
            let arg = rexArgs[i].split('@');
            pm.remove(arg[0], arg[1]);
        }
    } else if (rexArgs[0] == "il") {
        pm.install(rexArgs[1]);
    }
    pm.close();
    return 0;
}