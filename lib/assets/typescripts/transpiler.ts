//
// transpiler.ts
// typescript-rails
//

/// <reference types="typescript/lib/typescriptServices" />

namespace TypescriptRails {
    export enum ScriptType {
        Any,
        Javascript,
        Typescript,
    };

    /**
     * A class to transpile typescript into javascript in the browser, at
     * runtime.
     *
     * @export
     * @class Transpiler
     */
    export class Transpiler {
        public domBody: HTMLElement;

        constructor() {
            this._loadDOM();
        }

        /**
         * Set internal DOM properties.
         *
         * @private
         * @returns {void}
         *
         * @memberOf TypescriptRails
         */
        private _loadDOM(): void {
            this.domBody = document.getElementsByTagName("body")[0];

            return;
        }

        /**
         * Transpile all typescript scripts in DOM.
         *
         * All previous transpiled scripts will be removed before their source
         * is re-transpiled and re-appended to the DOM.
         *
         * @returns {void}
         *
         * @memberof Transpiler
         */
        public transpile(): void {
            let typescripts: HTMLScriptElement[] = this.domScripts(ScriptType.Typescript);
            let javascripts: HTMLScriptElement[] = [];

            // remove all transpiled scripts from DOM
            this.purgeTranspiledScripts();

            // transpile all typescripts
            for (const script of typescripts) {
                javascripts.push(this.transpileScript(script));
            }

            // append transpiled scripts to DOM
            this.appendScripts(javascripts);

            return;
        }

        /**
         * Transpile typescript script to javascript.
         *
         * @param {HTMLScriptElement} script The script object to transpile
         * @returns {HTMLScriptElement} The transpiled script object
         *
         * @memberof Transpiler
         */
        public transpileScript(script: HTMLScriptElement): HTMLScriptElement {
            if (script.type !== "text/typescript") return;

            console.log("dynamic ts transpiler: transpiling typescript");

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
            const jsContent = ts.transpileModule(script.text, compilerOptions);

            // create a new script node, insert transpiled content
            const element = document.createElement("script");
            element.type = "text/javascript";
            element.innerHTML = "// Transpiled TypeScript\n\n" + jsContent.outputText;

            return element;
        }

        /**
         * Append scripts to DOM.
         *
         * Script objects will be assigned an id that is a combination of the
         * prefix plus an incremented value.
         *
         * @param {HTMLScriptElement[]} scripts
         * @param {string} [prefix="drty-"] Object id prefix to filter targets
         * @returns {number} Number of scripts appended
         *
         * @memberof Transpiler
         */
        public appendScripts(scripts: HTMLScriptElement[], prefix: string = "drty-"): number {
            let counter: number = 0;

            for (const script of scripts) {
                script.id = `${prefix + counter}`
                this.domBody.appendChild(script);
                counter++;
            }

            return counter;
        }

        /**
         * Remove transpiled scripts from DOM.
         *
         * @param {string} [prefix="drty-"] Object id prefix to filter targets
         * @returns {number} Number of scripts removed
         *
         * @memberof Transpiler
         */
        public purgeTranspiledScripts(prefix: string = "drty-"): number {
            let counter: number = this.purgeScripts(ScriptType.Javascript, prefix);

            return counter;
        }

        /**
         * Remove scripts from DOM.
         *
         * @param {ScriptType} type Object script type
         * @param {string} prefix Object id prefix to filter targets
         * @returns {number} Number of scripts removed
         *
         * @memberof Transpiler
         */
        public purgeScripts(type: ScriptType, prefix: string): number {
            let scripts: HTMLScriptElement[] = this.domScripts(type, prefix);
            let counter: number = 0;

            for (const script of scripts) {
                this.domBody.removeChild(script);
                counter++;
            }

            return counter;
        }

        /**
         * Returns an array of script objects from DOM.
         *
         * This method returns all scripts if no idPrefix is provided.
         *
         * @private
         * @param {ScriptType} [type=ScriptType.Typescript] Object script type
         * @param {string} [prefix=""] Object id prefix to filter results
         * @returns {HTMLScriptElement[]} Array of script objects
         *
         * @memberof Transpiler
         */
        private domScripts(type: ScriptType = ScriptType.Typescript, prefix: string = ""): HTMLScriptElement[] {
            let nodes: NodeList = document.getElementsByTagName("script");
            let scripts: HTMLScriptElement[] = [];

            Array.prototype.forEach.call(nodes, (node, key, listObj, argument) => {
                const script = node as HTMLScriptElement;

                switch(type) {
                    case ScriptType.Javascript:
                        if (script.type !== "text/javascript" && script.type.length > 0) return;
                        break;

                    case ScriptType.Typescript:
                        if (script.type !== "text/typescript") return;
                        break;

                    default:
                        break;
                }

                const regex = new RegExp("^" + `${prefix}`);
                if (prefix.length === 0 || (script.id.length > 0 && regex.test(script.id))) {
                    scripts.push(script);
                }
            });

            return scripts;
        }
    } // class Transpiler
} // namespace TypescriptRails
