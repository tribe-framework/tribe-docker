<?php
/**
 * DO NOT MANUALLY MODIFY THIS FILE
 * THIS FILE EXISTS FOR BACKWARD COMPATIBILITY REASONS ONLY, TRY TO USE ".env"
 *
 * add custom variables to ".env" in project root or create a "vars.php"
 * in this directory if you want to add your own variables
 */

date_default_timezone_set($_ENV['DEFAULT_TIMEZONE']);

// set cors headers in PHP server
if ($_ENV['ALLOW_CROSS_ORIGIN'] === 'true') {
    if ($_ENV['ENV'] == 'prod') {
        $allowed_origins = [
            $_ENV['WEB_URL'],
            $_ENV['APP_URL'],
            $_ENV['JUNCTION_URL'],
            $_ENV['DOCKER_INTERNAL_TRIBE_URL'],
            $_ENV['DOCKER_INTERNAL_JUNCTION_URL'],
            $_ENV['DOCKER_EXTERNAL_TRIBE_URL'],
            $_ENV['DOCKER_EXTERNAL_JUNCTION_URL'],
        ];


        if (array_key_exists('HTTP_ORIGIN', $_SERVER)) {
            $_origin = $_SERVER["HTTP_ORIGIN"];
        } else if (array_key_exists('HTTP_HOST', $_SERVER)) {
            $_origin = $_SERVER["HTTP_HOST"];
        } else {
            $_origin = "";
        }

        header("Access-Control-Allow-Origin: $_origin");
        header("Access-Control-Allow-Headers: *");
        header("Access-Control-Allow-Methods: *");
    }
    //in dev environment, allowing cross origin *
    else {
        header("Access-Control-Allow-Origin: *");
        header("Access-Control-Allow-Headers: *");
        header("Access-Control-Allow-Methods: *");
    }
}

define('TRIBE_ROOT', dirname(__DIR__, 1));
define('ABSOLUTE_PATH', dirname(__DIR__, 1));
define('ENV', $_ENV['ENV']);
define('DB_NAME', $_ENV['DB_NAME']);
define('DB_USER', $_ENV['DB_USER']);
define('DB_PASS', $_ENV['DB_PASS']);
define('DB_HOST', $_ENV['DB_HOST']);
define('DB_PORT', $_ENV['DB_PORT']);
define('BARE_URL', $_ENV['WEB_BARE_URL']);
define('CONTACT_EMAIL', $_ENV['CONTACT_EMAIL']);
define('WEBSITE_NAME', $_ENV['WEBSITE_NAME']);
define('CONTACT_NAME', $_ENV['CONTACT_NAME']);
define('S3_BKUP_HOST_BASE', ($_ENV['S3_BKUP_HOST_BASE'] ?? ''));
define('S3_BKUP_HOST_BUCKET', ($_ENV['S3_BKUP_HOST_BUCKET'] ?? ''));
define('S3_BKUP_ACCESS_KEY', ($_ENV['S3_BKUP_ACCESS_KEY'] ?? ''));
define('S3_BKUP_SECRET_KEY', ($_ENV['S3_BKUP_SECRET_KEY'] ?? ''));
define('S3_BKUP_FOLDER_NAME', ($_ENV['S3_BKUP_FOLDER_NAME'] ?? ''));
define('BASE_URL', ($_ENV['SSL'] !== 'false' ? 'https' : 'http') . '://' . BARE_URL);
