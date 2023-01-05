let std = require("std");
let pmInfo = require(format("${str}/share/info.rex", rexPkgRoot));

func packageManager(args) {
    let result = {
        suzumeDB: null,     // the sqlite3 database object
        type: null,         // 1 is local, 0 is global
        suzumeInfo: null,   // initialize by the following steps
        pmRoot: null,       // initialize by the following steps
        initializeDB: func () {
            // initialize tables
            suzumeDB.executeScript(
                '
                create table suzumeInfo (
                    suzumeVersion   string  not null default "0.1",
                    suzumeBranch    string  not null default "dev",
                    suzumeRemote    string  not null default "",
                    suzumeApiVer    integer default 1,
                );
                create table installedPackages (
                    name            string  not null,
                    version         string  not null,
                    references      integer default 1,
                );
                '
            );
            suzumeDB.execute("insert into suzumeInfo (suzumeVersion, suzumeBranch, suzumeRemote)
                                values (?, ?, ?)", suzumeVersion, suzumeBranch, suzumeDefaultRemote);
            if (this.type == 0) {
                // global
                suzumeDB.execute("insert into installedPackages (name, version) values (?, ?)",
                                    "std", "0.1");
                suzumeDB.execute("insert into installedPackages (name, version) values (?, ?)",
                                    "suzume", "0.1");
            }
            suzumeDB.commit();
        },
        isInitalized: func () {
            return suzumeDB.execute("select name from sqlite_master where name='suzumeInfo'").length() == 1;
        },
        install: func (pkgName, pkgVersion) {
            
        },
        switchVersion: func (pkgName, pkgVersion) {
            
        },
        remove: func (pkgName, pkgVersion) {
            
        }
    };
    if (type(args.globalPM) != "null") {
        // initialize as local package manager
        result.type = 1;
        result.suzumeDB = std.sqlite.open(format("${str}/suzume.db", args.pkgRoot));
        result.suzumeInfo = args.globalPM.suzumeInfo;   // inherit from globalPM
        result.pmRoot = args.pkgRoot;
    } else {
        result.type = 0;
        result.suzumeDB = std.sqlite.open(format("${str}/../../suzume.db", rexPkgRoot));
        result.pmRoot = format("${str}/../..", rexPkgRoot);
    }
    return result;
}