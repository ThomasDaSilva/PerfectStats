<?php

namespace PerfectStats\Hook;

use PerfectStats\PerfectStats;
use Thelia\Core\Event\Hook\HookRenderEvent;
use Thelia\Core\Hook\BaseHook;

class AdminMenuHook extends BaseHook
{

    public function onMainInTopMenuItems(HookRenderEvent $event)
    {
        $event->add(
            $this->render('PerfectStats/hook/main.in.top.menu.items.html', [])
        );
    }
}
