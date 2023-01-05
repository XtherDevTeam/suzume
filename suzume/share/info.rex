let suzumeVersion = "0.1";
let suzumeBranch = "dev";
let suzumeApiVersion = 1;
let suzumeDefaultRemote = "http://www.xiaokang00010.top:5915/rex";

let getSuzumeInfo = func () {
    return format("Suzume (reXscript Package Manager) ${str}@${str} (API ${int bs=dec})", 
                    suzumeVersion, suzumeBranch, suzumeApiVersion);
};