//
// gulpfile.js
// typescript-rails
//
var gulp = require("gulp");
var ts = require("gulp-typescript");
var uglify = require("gulp-uglify");
var rename = require("gulp-rename");
var buffer = require("vinyl-buffer");

var tsProject = ts.createProject("tsconfig.json");
var jsOutputDir = "lib/assets/javascripts";

gulp.task("transpile", function() {
  var tsResult = tsProject.src()
    .pipe(tsProject());

    return tsResult.js
      .pipe(gulp.dest("dist"));
});

gulp.task("transpile-min", function() {
  var tsResult = tsProject.src()
    .pipe(tsProject());

    return tsResult.js
      .pipe(rename({ basename: "dyrt" }))
      .pipe(gulp.dest(jsOutputDir))
      .pipe(buffer())
      .pipe(uglify())
      .pipe(rename({ suffix: ".min" }))
      .pipe(gulp.dest(jsOutputDir));
});

gulp.task("watch", ["scripts"], function() {
    gulp.watch("lib/assets/typescripts/*.ts", ["transpile"]);
});
