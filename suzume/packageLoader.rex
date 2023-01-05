let std = require("std");

let api = require(format("${str}/backend/api.rex", rexPkgRoot));

func rexModInit() {
    print("Konnichiha, Sekai!\n");
    let pm = api.packageManager({
        globalPM: null,
        pkgRoot: null
    });
    print(pm, "\n");
    return 0;
}