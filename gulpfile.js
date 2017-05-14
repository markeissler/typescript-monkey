//
// gulpfile.js
// typescript-rails
//
var gulp = require("gulp");
var ts = require("gulp-typescript");
var uglify = require("gulp-uglify");
var rename = require("gulp-rename");
var concat = require("gulp-concat");
var ignore = require("gulp-ignore");
var debug = require('gulp-debug');
var runSequence = require('run-sequence');

var tsProject = ts.createProject("tsconfig.json");
var jsOutputDir = "lib/assets/javascripts";

gulp.task("transpile", function() {
  var tsResult = tsProject.src()
    .pipe(ignore.include(/transpiler.ts$/))
    .pipe(tsProject());

  return tsResult.js
    .pipe(rename({ basename: "dyrt" }))
    .pipe(gulp.dest(jsOutputDir));
});

gulp.task("transpile-min", function() {
  var tsResult = tsProject.src()
    .pipe(ignore.include(/transpiler.ts$/))
    .pipe(tsProject());

  return tsResult.js
    .pipe(rename({ basename: "dyrt" }))
    .pipe(gulp.dest(jsOutputDir))
    .pipe(uglify())
    .pipe(rename({ suffix: ".min" }))
    .pipe(gulp.dest(jsOutputDir));
});

gulp.task("transpile-once", function() {
  var tsResult = tsProject.src()
    .pipe(tsProject());

  return tsResult.js
    .pipe(concat('dyrt_once.js'))
    .pipe(gulp.dest(jsOutputDir));
});

gulp.task("transpile-once-min", function() {
  var tsResult = tsProject.src()
    .pipe(tsProject());

  return tsResult.js
    .pipe(concat('dyrt_once.js'))
    .pipe(gulp.dest(jsOutputDir))
    .pipe(uglify())
    .pipe(rename({ suffix: ".min" }))
    .pipe(gulp.dest(jsOutputDir));
});

gulp.task("all", function() {
  runSequence("transpile-min", "transpile-once-min");
});

gulp.task("watch", ["transpile"], function() {
  gulp.watch("lib/assets/typescripts/*.ts", ["transpile"]);
});
