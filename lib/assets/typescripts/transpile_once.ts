//
// transpile_once.ts
// typescript-monkey
//
// Run the transpiler once against the DOM.
//

/// <reference path="./transpiler.ts" />

(() => {
    const transpiler = new TypescriptRails.Transpiler();
    transpiler.transpile();
})();
