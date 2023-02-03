let std = require("std");
let log = require(format("${str}/share/log.rex", rexPkgRoot));
let network = require(format("${str}/backend/network.rex", rexPkgRoot));
let pmInfo = require(format("${str}/share/info.rex", rexPkgRoot));

func packageManager(args) {
    let result = {
        globalPM: null,
        suzumeDB: null,     // the sqlite3 database object
        type: null,         // 1 is local, 0 is global
        suzumeInfo: null,   // initialize by the following steps
        pmRoot: null,       // initialize by the following steps
        remoteAPI: null,
        initializeDB: func () {
            // initialize tables
            this.suzumeDB.executeScript(
                '
                create table suzumeInfo (
                    suzumeVersion   text    not null default "0.1",
                    suzumeBranch    text    not null default "dev",
                    suzumeRemote    text    not null default "",
                    suzumeApiVer    integer not null default 1
                );
                create table installedPackages (
                    name            text    not null,
                    version         text    not null,
                    ref             integer not null default 1
                );
                '
            );
            this.suzumeDB.execute("insert into suzumeInfo (suzumeVersion, suzumeBranch, suzumeRemote, suzumeApiVer)
                                    values (?, ?, ?, ?)", pmInfo.suzumeVersion, pmInfo.suzumeBranch, pmInfo.suzumeDefaultRemote, pmInfo.suzumeApiVersion);
            if (this.type == 0) {
                // global
                this.updateInstalledPackages("std", "0.1");
                this.updateInstalledPackages("suzume", "0.1");
            }
            return null;
        },
        updateInstalledPackages: func (name, version) {
            this.suzumeDB.execute("insert into installedPackages (name, version) values (?, ?)", 
                name, version);
            return true;
        },
        isInitalized: func () {
            let result = this.suzumeDB.execute("select name from sqlite_master where name='suzumeInfo'");
            return result.length() == 1;
        },
        getRefNum: func (pkgName, pkgVersion) {
            // 0 is that not installed.
            let result = this.suzumeDB.execute("select * from installedPackages where name = ? and version = ?", pkgName, pkgVersion);
            if (result.length() == 0) {
                return 0;
            } else {
                return result[0].ref;
            }
        },
        query: func (pkgName, pkgVersion) {
            // query package is installed, returns 1 if installed with the required version, 0 if installed an different version, otherwise, package not installed
            let result = this.suzumeDB.execute(
                "
                select * from installedPackages
                where name = ?
                order by case
                    when version = ? then 1
                    else 2
                end asc
                "
            , pkgName, pkgVersion);
            if (result.length() > 0) {
                if (result[0].version.decode("utf-8") == pkgVersion) {
                    return 1;
                } else {
                    return 0;
                }
            } else {
                return 2;
            }
        },
        updateRef: func (pkgName, pkgVersion, refCnt) {
            this.suzumeDB.execute("update installedPackages set ref = ? where name = ? and version = ?", refCnt, pkgName, pkgVersion);
            return null;
        },
        install: func (pkgPath) {
            let pkgFp = std.fs.open(format("${str}/suzume.json", pkgPath), "r+");
            let pkgFile = std.json.loads(pkgFp.read(pkgFp.length).decode("utf-8"));
            pkgFp.close();
            if (this.query(pkgFile.name, pkgFile.version) == 1) {
                log.log(log.logLevel.info, format("Already installed: ${str}@${str}", pkgFile.name, pkgFile.version));
            }
            log.log(log.logLevel.info, format("Installing package ${str}@${str}...", pkgFile.name, pkgFile.version));
            log.log(log.logLevel.info, "Checking dependencies...");
            object.iterate(pkgFile.dependencies, lambda (this) -> (k, v) {
                // query from globalPM
                if (type(outer.this.globalPM) != 'null') {
                    let queryResult = outer.this.globalPM.query(k, v);
                    if (queryResult == 1) {
                        return null;
                    }
                }
                let queryResult = outer.this.query(k, v);
                if (queryResult == 0) {
                    throw {"errName": "suzumeError", "errMsg": format("Unsatisfied package dependencies: required ${str} version ${str}, but an different version have been installed.", k, v)};
                } else if (queryResult == 2) {
                    if (outer.this.installFromRemote(k, v) == false) {
                        throw {"errName": "suzumeError", "errMsg": format("Unsatisfied package dependencies: required ${str} version ${str}, but package not installed.", k, v)};
                    }
                }
                return null;
            });
            log.log(log.logLevel.info, "Copying files...");
            std.fs.copy(pkgPath, format("${str}/modules/${str}@${str}", this.pmRoot, pkgFile.name, pkgFile.version));
            log.log(log.logLevel.info, "Updating registry...");
            this.updateInstalledPackages(pkgFile.name, pkgFile.version);
            if (this.type == 1) {
                log.log(log.logLevel.info, "Updating suzume.json...");
                let fp = std.fs.open(format("${str}/suzume.json", this.pmRoot), "r+");
                let file = std.json.loads(fp.read(fp.length).decode("utf-8"));
                fp.close();
                object.addAttr(file.dependencies, pkgFile.name, pkgFile.version);
                let fp = std.fs.open(format("${str}/suzume.json", this.pmRoot), "w+");                
                fp.write(std.json.dumps(file).encode("utf-8"));
                fp.close();
            }
            log.log(log.logLevel.info, "Complete...");
        },
        switchVersion: func (pkgName, pkgVersion) {
            let queryResult = this.query(pkgName, pkgVersion);
            if (queryResult == 2) {
                log.log(log.logLevel.error, "Unable to switch package version: package not exist: ${pkgName}", pkgName);
            } else if (queryResult == 1) {
                log.log(log.logLevel.error, "Already installed: ${pkgName}@${pkgVersion}", pkgName, pkgVersion);
            } else {
                this.remove(pkgName, pkgVersion);
                this.installFromRemote(pkgName, pkgVersion);
            }
        },
        remove: func (pkgName, pkgVersion) {
            // remove packages
            let refNum = this.getRefNum(pkgName, pkgVersion);
            if (refNum == 1) {
                log.log(log.logLevel.debug, format("Removing: ${str}@${str}", pkgName, pkgVersion));
                std.fs.removeAll(format("${str}/modules/${str}@${str}", this.pmRoot, pkgName, pkgVersion));
                this.suzumeDB.execute("delete from installedPackages where name = ? and version = ?", pkgName, pkgVersion);
                if (this.type == 1) {
                    log.log(log.logLevel.info, "Updating suzume.json...");
                    let fp = std.fs.open(format("${str}/suzume.json", this.pmRoot), "r+");
                    let file = std.json.loads(fp.read(fp.length).decode("utf-8"));
                    fp.close();
                    object.removeAttr(file.dependencies, pkgFile.name);
                    let fp = std.fs.open(format("${str}/suzume.json", this.pmRoot), "w+");                
                    fp.write(std.json.dumps(file).encode("utf-8"));
                    fp.close();
                }
                log.log(log.logLevel.debug, "Done");
                return true;
            } else if (refNum == 0) {
                log.log(log.logLevel.error, format("Package not exist: ${str}@${str}", pkgName, pkgVersion));
                return false;
            } else {
                log.log(log.logLevel.error, format("Package has been referenced by other packages: ${str}@${str}", pkgName, pkgVersion));
                return false;
            }
        },
        close: func () {
            this.suzumeDB.close();
            return null;
        },
        open: func () {
            if(this.isInitalized() == false) {
                log.log(log.logLevel.debug, "Database is not initialized, initializing...");
                this.initializeDB();
                log.log(log.logLevel.debug, "Initialized database...");
            }
            this.suzumeInfo = this.suzumeDB.execute("select * from suzumeInfo");
            this.suzumeInfo = this.suzumeInfo[0];

            log.log(log.logLevel.debug, "Initializing RemoteAPI...");
            this.remoteAPI = network.remote(this.suzumeInfo.suzumeRemote.decode('utf-8'));
            log.log(log.logLevel.debug, "Suzume instance is ready...");
            return null;
        },
        installFromRemote: func(pkgName, pkgVersion) {
            if (this.query(pkgName, pkgVersion) == 1) {
                log.log(log.logLevel.info, format("Already installed: ${str}@${str}", pkgName, pkgVersion));
                return false;
            }
            let downloadedPath = this.remoteAPI.download(pkgName, pkgVersion, std.fs.temp());
            if (type(downloadedPath) != "null") {
                let dirPath = format("${str}/${str}@${str}", std.fs.temp(), pkgName, pkgVersion);
                std.fs.mkdirs(dirPath);

                // extract and install
                std.zip.extract(downloadedPath, dirPath, lambda () -> (filename) {
                    log.log(log.logLevel.debug, format("Extracting ${str}...", filename));
                    return null;
                });
                this.install(dirPath);

                log.log(log.logLevel.debug, "Cleaning temp files...");
                std.fs.removeAll(dirPath);
                std.fs.removeAll(downloadedPath);
                log.log(log.logLevel.debug, "Done!");
                return true;
            } else {
                log.log(log.logLevel.debug, format("Package not exist on remote: ${str}@${str}", pkgName, pkgVersion));
                return false;
            }
        }
    };
    if (type(args.globalPM) != "null") {
        // initialize as local package manager
        result.type = 1;
        result.suzumeDB = std.sqlite.open(format("${str}/suzume.db", args.pkgRoot));
        result.suzumeInfo = args.globalPM.suzumeInfo;   // inherit from globalPM
        result.pmRoot = args.pkgRoot;
        result.globalPM = args.globalPM;
    } else {
        result.type = 0;
        result.suzumeDB = std.sqlite.open(format("${str}/../../suzume.db", rexPkgRoot));
        result.pmRoot = format("${str}/../..", rexPkgRoot);
    }
    return result;
}