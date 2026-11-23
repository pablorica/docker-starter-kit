<?php

/**
 * WP-CLI stubs for Intelephense.
 *
 * This file is for IDE/static analysis only.
 * Do not load it in WordPress.
 */

if (!class_exists('WP_CLI')) {
    class WP_CLI {

        /**
         * Display an informational message.
         *
         * @param string $message
         * @return void
         */
        public static function log($message = '') {}

        /**
         * Display a success message.
         *
         * @param string $message
         * @return void
         */
        public static function success($message) {}

        /**
         * Display a warning message.
         *
         * @param string $message
         * @return void
         */
        public static function warning($message) {}

        /**
         * Display an error message and optionally exit.
         *
         * @param string $message
         * @param bool   $exit
         * @return void
         */
        public static function error($message, $exit = true) {}

        /**
         * Register a WP-CLI command.
         *
         * @param string   $name
         * @param callable|object|string $callable
         * @param array    $args
         * @return void
         */
        public static function add_command($name, $callable, $args = []) {}

        /**
         * Display debug information.
         *
         * @param string $message
         * @param string|false $group
         * @return void
         */
        public static function debug($message, $group = false) {}

        /**
         * Display a message without a trailing newline.
         *
         * @param string $message
         * @return void
         */
        public static function line($message = '') {}

        /**
         * Display a message and exit.
         *
         * @param int $code
         * @return void
         */
        public static function halt($code) {}
    }
}