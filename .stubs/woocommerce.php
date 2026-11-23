<?php



/**
 * WooCommerce development stubs.
 *
 * This file is only for IDE type resolution.
 * Do not include or require it from WordPress.
 */

/**
 * Conditional functions.
 */

if (!function_exists('is_shop')) {
  function is_shop(): bool
  {
    return false;
  }
}

if (!function_exists('is_checkout')) {
  function is_checkout(): bool
  {
    return false;
  }
}

if (!function_exists('is_cart')) {
  function is_cart(): bool
  {
    return false;
  }
}

if (!function_exists('is_account_page')) {
  function is_account_page(): bool
  {
    return false;
  }
}

if (!function_exists('is_product')) {
  function is_product(): bool
  {
    return false;
  }
}

if (!function_exists('is_product_category')) {
  function is_product_category(
    string|array $term = ''
  ): bool {
    return false;
  }
}

if (!function_exists('is_product_tag')) {
  function is_product_tag(
    string|array $term = ''
  ): bool {
    return false;
  }
}

/**
 * Page helpers.
 */

if (!function_exists('wc_get_page_id')) {
  function wc_get_page_id(string $page): int
  {
    return 0;
  }
}

/**
 * Deprecated WooCommerce page helper.
 *
 * @deprecated Use wc_get_page_id().
 */
if (!function_exists('woocommerce_get_page_id')) {
  function woocommerce_get_page_id(string $page): int
  {
    return 0;
  }
}

/**
 * Product helpers.
 */



if (!function_exists('get_product')) {
  function get_product(
    int|WP_Post|WC_Product $product = 0
  ): WC_Product|false {
    return false;
  }
}

if (!function_exists('wc_get_product')) {
  function wc_get_product(
    int|WP_Post|WC_Product $product = 0
  ): WC_Product|false {
    return false;
  }
}

if (!function_exists('wc_get_products')) {
  /**
   * @return WC_Product[]
   */
  function wc_get_products(array $args = []): array
  {
    return [];
  }
}

/**
 * Main WooCommerce accessor.
 * @return WooCommerce
 */
function WC()
{
    return new WooCommerce();
}

/**
 * Core WooCommerce classes.
 */

if (!class_exists('WooCommerce')) {
  class WooCommerce
  {
    public ?WC_Cart $cart = null;
    public ?WC_Customer $customer = null;
    public ?WC_Session $session = null;

    public function cart(): WC_Cart
    {
      return new WC_Cart();
    }

    public function customer(): WC_Customer
    {
      return new WC_Customer();
    }

    public function session(): WC_Session
    {
      return new WC_Session();
    }
  }
}

if (!class_exists('WC_Cart')) {
  class WC_Cart
  {
    public function add_to_cart(
      int $product_id,
      int $quantity = 1,
      int $variation_id = 0,
      array $variation = [],
      array $cart_item_data = []
    ): string|false {
      return false;
    }

    public function get_cart_contents_count(): int
    {
      return 0;
    }

    public function get_cart_total(): string
    {
      return '';
    }

    public function get_cart_subtotal(): string
    {
      return '';
    }

    public function get_total(string $context = 'view'): string
    {
      return '';
    }

    public function empty_cart(bool $clear_persistent_cart = true): void {}

    public function is_empty(): bool
    {
      return true;
    }

    /**
     * @return array<string, array<string, mixed>>
     */
    public function get_cart(): array
    {
      return [];
    }

    public function get_cart_url(string $context = 'view'): string
    {
      return '';
    }

    public function get_product_price(string $context = 'view'): string
    {
      return '';
    }

    public function get_checkout_url(string $context = 'view'): string
    {
      return '';
    }
  }
}

if (!class_exists('WC_Product')) {
  class WC_Product
  {
    public function get_id(): int
    {
      return 0;
    }

    public function get_name(): string
    {
      return '';
    }

    public function get_sku(): string
    {
      return '';
    }

    public function get_price(string $context = 'view'): string
    {
      return '';
    }

    public function get_regular_price(string $context = 'view'): string
    {
      return '';
    }

    public function get_sale_price(string $context = 'view'): string
    {
      return '';
    }

    public function get_permalink(): string
    {
      return '';
    }

    public function get_image_id(string $context = 'view'): int
    {
      return 0;
    }

    public function is_in_stock(): bool
    {
      return true;
    }

    public function is_on_sale(string $context = 'view'): bool
    {
      return false;
    }
    public function is_type(string $context = 'view'): bool
    {
      return false;
    }
  }
}

if (!class_exists('WC_Customer')) {
  class WC_Customer
  {
    public function get_id(): int
    {
      return 0;
    }

    public function get_email(string $context = 'view'): string
    {
      return '';
    }

    public function get_first_name(string $context = 'view'): string
    {
      return '';
    }

    public function get_last_name(string $context = 'view'): string
    {
      return '';
    }
  }
}

if (!class_exists('WC_Session')) {
  class WC_Session
  {
    public function get(
      string $key,
      mixed $default = null
    ): mixed {
      return $default;
    }

    public function set(string $key, mixed $value): void {}

    public function __unset(string $key): void {}
  }
}

if (!class_exists('WC_Order')) {
  class WC_Order
  {
    public function get_id(): int
    {
      return 0;
    }

    public function get_status(): string
    {
      return '';
    }

    public function get_total(string $context = 'view'): string
    {
      return '';
    }

    public function get_billing_email(string $context = 'view'): string
    {
      return '';
    }
  }
}
