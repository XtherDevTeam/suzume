cmake_rex:
	cd reXscript; make cmake

build_rex:
	cd reXscript; make build

build_stdlib:
	cd rexStdlib; make dist

clean:
	rm -rf dist
	rm -rf rexStdlib/dist

dist: clean cmake_rex build_rex build_stdlib
	mkdir -p dist/
	mkdir -p dist/modules/std
	mkdir -p dist/modules/suzume
	cp reXscript/cmake-build-debug/rex dist/
	cp -r rexStdlib/dist/* dist/modules/std/
	cp -r suzume/* dist/modules/suzume/

cmake_rex_prod:
	cd reXscript; make cmake_prod

build_rex_prod:
	cd reXscript; make build_prod

build_stdlib_prod:
	cd rexStdlib; make dist_prod


dist_prod: clean cmake_rex_prod build_rex_prod build_stdlib_prod
	mkdir -p dist/
	mkdir -p dist/modules/std
	mkdir -p dist/modules/suzume
	cp reXscript/cmake-build-release/rex dist/
	cp -r rexStdlib/dist/* dist/modules/std/
	cp -r suzume/* dist/modules/suzume/

update_upstream:
	cd reXscript; git pull origin master; cd ..
	cd rexStdlib; git pull origin master; cd ..