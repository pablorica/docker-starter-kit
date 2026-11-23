<?php

/**
 * Advanced Custom Fields (ACF) stubs for Intelephense.
 *
 * This file is for IDE/static analysis only.
 * It should never be loaded by WordPress.
 */

if (!function_exists('get_field')) {
    /**
     * @param string|int $selector
     * @param mixed      $post_id
     * @param bool       $format_value
     * @param bool       $escape_html
     * @return mixed
     */
    function get_field($selector, $post_id = false, $format_value = true, $escape_html = false) {}
}

if (!function_exists('the_field')) {
    /**
     * @param string|int $selector
     * @param mixed      $post_id
     * @param bool       $format_value
     * @return void
     */
    function the_field($selector, $post_id = false, $format_value = true) {}
}

if (!function_exists('have_rows')) {
    /**
     * @param string|int $selector
     * @param mixed      $post_id
     * @return bool
     */
    function have_rows($selector, $post_id = false) {}
}

if (!function_exists('the_row')) {
    /**
     * @return void
     */
    function the_row() {}
}

if (!function_exists('get_row')) {
    /**
     * @return array|false
     */
    function get_row() {}
}

if (!function_exists('get_row_layout')) {
    /**
     * @return string|false
     */
    function get_row_layout() {}
}

if (!function_exists('get_sub_field')) {
    /**
     * @param string|int $selector
     * @param bool       $format_value
     * @param bool       $escape_html
     * @return mixed
     */
    function get_sub_field($selector, $format_value = true, $escape_html = false) {}
}

if (!function_exists('the_sub_field')) {
    /**
     * @param string|int $selector
     * @param bool       $format_value
     * @return void
     */
    function the_sub_field($selector, $format_value = true) {}
}

if (!function_exists('get_field_object')) {
    /**
     * @param string|int $selector
     * @param mixed      $post_id
     * @param bool       $format_value
     * @param bool       $load_value
     * @param bool       $escape_html
     * @return array|false
     */
    function get_field_object(
        $selector,
        $post_id = false,
        $format_value = true,
        $load_value = true,
        $escape_html = false
    ) {}
}

if (!function_exists('get_field_objects')) {
    /**
     * @param mixed $post_id
     * @param bool  $format_value
     * @param bool  $load_value
     * @param bool  $escape_html
     * @return array|false
     */
    function get_field_objects(
        $post_id = false,
        $format_value = true,
        $load_value = true,
        $escape_html = false
    ) {}
}

if (!function_exists('update_field')) {
    /**
     * @param string|int $selector
     * @param mixed      $value
     * @param mixed      $post_id
     * @return bool|int
     */
    function update_field($selector, $value, $post_id = false) {}
}

if (!function_exists('update_sub_field')) {
    /**
     * @param string|array $selector
     * @param mixed        $value
     * @param mixed        $post_id
     * @return bool
     */
    function update_sub_field($selector, $value, $post_id = false) {}
}

if (!function_exists('acf_add_options_page')) {
    /**
     * @param array|string $settings
     * @return array|false
     */
    function acf_add_options_page($settings = []) {}
}

if (!function_exists('acf_add_options_sub_page')) {
    /**
     * @param array|string $settings
     * @return array|false
     */
    function acf_add_options_sub_page($settings = []) {}
}

if (!function_exists('acf_register_block_type')) {
    /**
     * @param array $settings
     * @return array|false
     */
    function acf_register_block_type($settings) {}
}