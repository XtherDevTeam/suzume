let logLevel = {
    debug: -1,
    info: 0,
    warning: 1,
    error: 2,
};

let printableLevel = logLevel.debug;

let std = require('std');

func log(level, str) {
    let mapping = hashMap();
    mapping.insert(-1, "DEBUG");
    mapping.insert(0, "INFO");
    mapping.insert(1, "WARN");
    mapping.insert(2, "ERR");
    if (level >= printableLevel) {
        print(format("[${str}/${str}] ${str}\n", 
            std.time.time().format("%Y-%m-%d %H:%M:%S"), mapping[level], str));
    }
}