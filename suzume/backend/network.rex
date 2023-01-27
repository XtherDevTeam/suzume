let std = require("std");
let log = require(format("${str}/share/log.rex", rexPkgRoot));

func remote(url) {
    return {
        url: url,
        query: func (pkgName, pkgVersion) {
            let remoteUrl = format("${str}/download/${str}/${str}-${str}-${str}.zip", 
                this.url, pkgName, pkgVersion, rexPlatform, rexArch);
            log.log(log.logLevel.debug, format("Querying url: ${str}", remoteUrl));
            let response = std.net.http.open("GET", remoteUrl, {});
            if (response.headers.statusCode != 200) {
                log.log(log.logLevel.debug, format("remote.query(): Failed with ${int bs=dec} ${str}", 
                        response.headers.statusCode, response.headers.statusText));
                return false;
            } else {
                return true;
            }
        },
        download: func (pkgName, pkgVersion, dir) {
            // download a package from remote, and returns the file path if success, otherwise, returns null
            let remoteUrl = format("${str}/download/${str}/${str}-${str}-${str}.zip", 
                this.url, pkgName, pkgVersion, rexPlatform, rexArch);
            log.log(log.logLevel.debug, format("Downloading url: ${str}", remoteUrl));
            let response = std.net.http.open("GET", remoteUrl, {});
            if (response.headers.statusCode == 200) {
                let filename = format("${str}-${str}-${str}-${str}.zip", pkgName, pkgVersion, rexPlatform, rexArch);
                let file = std.fs.open(format("${str}/${str}", dir, filename), "w+");
                log.log(log.logLevel.info, format("remote.download(): downloading files with filename ${str}", filename));
                response.recv(lambda (file) -> (chunk) {
                    outer.file.write(chunk);
                });
                file.close();
                return format("${str}/${str}", dir, filename);
            } else {
                log.log(log.logLevel.debug, format("remote.download(): Failed with ${int bs=dec} ${str}", 
                        response.headers.statusCode, response.headers.statusText));
                return null;
            }
        },
        publish: func (token, pkgName, pkgVersion) {
            // TODO: not finished yet.
            return null;
        }
    };
}