import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import globals from "globals";

export default tseslint.config(
    {
        ignores: ["public/**", "release/**", "build/**", "dist/**", "node_modules/**"],
        languageOptions: {
            globals: {
                ...globals.browser,
                ...globals.node,
            },
        },

    },
    eslint.configs.recommended,
    tseslint.configs.strict,
    tseslint.configs.stylistic
);
