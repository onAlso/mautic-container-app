<?php

/*
 * @copyright   2021 onAlso Electronics Inc. All rights reserved
 * @author      onAlso Electronics Inc.
 *
 * @link        http://www.onalso.org
 *
 * @license     GNU/GPLv3 http://www.gnu.org/licenses/gpl-3.0.html
 */
define('MAUTIC_ROOT_DIR', __DIR__);

require_once 'autoload.php';

use Mautic\CoreBundle\ErrorHandler\ErrorHandler;
use Mautic\Middleware\MiddlewareBuilder;
use Symfony\Component\HttpFoundation\Request;
use function Stack\run;

ErrorHandler::register('prod');

$health_check_uri = getenv('HEALTH_CHECK_URI') or 'http://localhost/ping';
$request = Request::create($health_check_uri);

run((new MiddlewareBuilder(new AppKernel('prod', false)))->resolve(), $request);

