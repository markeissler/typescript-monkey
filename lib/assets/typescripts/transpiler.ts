//
// transpiler.ts
//

/// <reference types="typescript/lib/typescriptServices" />
let nodeList: NodeList = document.getElementsByTagName("script");
Array.prototype.forEach.call(nodeList, (node, key, listObj, argument) => {
    const script = node as HTMLScriptElement;
    if (script.type !== "text/typescript") {
        console.log("dynamic ts transpiler: skipping javascript");
        return;
    }

    console.log("dynamic ts transpiler: transpiling typescript");

    const tsContent = script.text;

    const compilerOptions: ts.TranspileOptions = {
        compilerOptions: {
            module: ts.ModuleKind.CommonJS,
        },
        fileName: undefined,
        reportDiagnostics: false,
        moduleName: undefined,
        renamedDependencies: undefined,
    } as ts.TranspileOptions;

    // transpile script content
    const jsContent = ts.transpileModule(tsContent, compilerOptions);

    // append transpiled content into a new node at the end of body
    const body = document.getElementsByTagName("body")[0];
    const element = document.createElement("script");
    element.type = "text/javascript";
    element.innerHTML = "// Transpiled TypeScript\n\n" + jsContent.outputText;
    body.appendChild(element);
});
