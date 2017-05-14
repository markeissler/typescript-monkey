//
// transpile_once.ts
// typescript-rails
//
// Run the transpiler once against the DOM.
//

/// <reference path="./transpiler.ts" />

(() => {
    const transpiler = new TypescriptRails.Transpiler();
    transpiler.transpile();
})();
