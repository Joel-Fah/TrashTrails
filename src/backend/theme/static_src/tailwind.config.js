/**
 * This is a minimal config.
 *
 * If you need the full config, get it from here:
 * https://unpkg.com/browse/tailwindcss@latest/stubs/defaultConfig.stub.js
 */

module.exports = {
    content: [
        /**
         * HTML. Paths to Django template files that will contain Tailwind CSS classes.
         */

        /*  Templates within theme app (<tailwind_app_name>/templates), e.g. base.html. */
        '../templates/**/*.html',

        /*
         * Main templates directory of the project (BASE_DIR/templates).
         * Adjust the following line to match your project structure.
         */
        '../../templates/**/*.html',

        /*
         * Templates in other django apps (BASE_DIR/<any_app_name>/templates).
         * Adjust the following line to match your project structure.
         */
        '../../**/templates/**/*.html',

        /**
         * Python files. Paths to Django form files that will contain Tailwind CSS classes.
         */
        '../../**/forms.py',

        /**
         * JS: If you use Tailwind CSS in JavaScript, uncomment the following lines and make sure
         * patterns match your project structure.
         */
        /* JS 1: Ignore any JavaScript in node_modules folder. */
        // '!../../**/node_modules',
        /* JS 2: Process all JavaScript files in the project. */
        // '../../**/*.js',

        /**
         * Python: If you use Tailwind CSS classes in Python, uncomment the following line
         * and make sure the pattern below matches your project structure.
         */
        // '../../**/*.py'
    ],
    theme: {
        extend: {
            fontFamily: {
                sans: ['General Sans', 'sans-serif'],
            },
            colors: {
                // TODO: customize the color palette here
                primary: {
                    DEFAULT: '#366a91',
                    50: '#f4f7fb',
                    100: '#e8eff6',
                    200: '#ccddeb',
                    300: '#9fc2da',
                    400: '#6ba1c5',
                    500: '#4886af',
                    600: '#366a91',
                    700: '#2d5677',
                    800: '#294a63',
                    900: '#263f54',
                    950: '#192938',
                },

                // Neutrals
                darkColor: '#1d1d1d',
                whiteColor: '#f5f5f5',
                greyColor: '#8d8d8d',

                // States
                success: '#0f9d58',
                danger: '#db4437',
                warning: '#f4b400',
                info: '#4285f4',
            }
        },
    },
    plugins: [
        /**
         * '@tailwindcss/forms' is the forms plugin that provides a minimal styling
         * for forms. If you don't like it or have own styling for forms,
         * comment the line below to disable '@tailwindcss/forms'.
         */
        require('@tailwindcss/forms'),
        require('@tailwindcss/typography'),
        require('@tailwindcss/aspect-ratio'),
    ],
}
