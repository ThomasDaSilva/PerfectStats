<?php

namespace PerfectStats\Controller;

use PerfectStats\Service\PerfectStatsService;
use Thelia\Controller\Admin\BaseAdminController;

class PerfectStatsController extends BaseAdminController
{
    protected $perfectStatsService;

    private $monthKeys = [
        1 => 'perfectstats.month.january',   2 => 'perfectstats.month.february',
        3 => 'perfectstats.month.march',      4 => 'perfectstats.month.april',
        5 => 'perfectstats.month.may',        6 => 'perfectstats.month.june',
        7 => 'perfectstats.month.july',       8 => 'perfectstats.month.august',
        9 => 'perfectstats.month.september', 10 => 'perfectstats.month.october',
        11 => 'perfectstats.month.november', 12 => 'perfectstats.month.december'
    ];

    public function __construct(PerfectStatsService $perfectStatsService)
    {
        $this->perfectStatsService = $perfectStatsService;
    }

    private function getMonthName($month): string
    {
        $key = $this->monthKeys[$month] ?? 'perfectstats.month.january';
        return $this->getTranslator()->trans($key, [], 'perfectstats.bo.default');
    }

    protected function getCurrentLocale(): string
    {
        try {
            $session = $this->getRequest()->getSession();
            if ($session) {
                $lang = $session->getLang();
                if ($lang) return $lang->getLocale();
            }
        } catch (\Exception $e) {}
        return 'fr_FR';
    }


    private function getDateRanges(): array
    {
        $now     = new \DateTime();
        $mode    = $this->getRequest()->query->get('mode', 'month');
        $year    = (int)($this->getRequest()->query->get('year', $now->format('Y')));
        $prevYear = $year - 1;

        switch ($mode) {
            case 'day':
                $month = (int)($this->getRequest()->query->get('month', $now->format('n')));
                $day   = (int)($this->getRequest()->query->get('day',   $now->format('j')));
                $cur  = $this->perfectStatsService->getDayDateRange($year,     $month, $day);
                $prev = $this->perfectStatsService->getDayDateRange($prevYear, $month, $day);
                break;
            case 'week':
                $week = (int)($this->getRequest()->query->get('week', (int)$now->format('W')));
                $cur  = $this->perfectStatsService->getWeekDateRange($year,     $week);
                $prev = $this->perfectStatsService->getWeekDateRange($prevYear, $week);
                break;
            case 'quarter':
                $quarter = (int)($this->getRequest()->query->get('quarter', (int)ceil((int)$now->format('n') / 3)));
                $cur  = $this->perfectStatsService->getQuarterDateRange($year,     $quarter);
                $prev = $this->perfectStatsService->getQuarterDateRange($prevYear, $quarter);
                break;
            case 'month':
                $month = (int)($this->getRequest()->query->get('month', $now->format('n')));
                $cur  = $this->perfectStatsService->getMonthDateRange($year,     $month);
                $prev = $this->perfectStatsService->getMonthDateRange($prevYear, $month);
                break;
            default:
                $cur  = $this->perfectStatsService->getYearDateRange($year);
                $prev = $this->perfectStatsService->getYearDateRange($prevYear);
        }

        return [$cur, $prev, $year, $prevYear];
    }

    private function errorResponse(\Exception $e, string $action): \Symfony\Component\HttpFoundation\Response
    {
        error_log('PerfectStats ' . $action . ' Error: ' . $e->getMessage() . ' - ' . $e->getTraceAsString());
        return $this->jsonResponse(json_encode(['error' => true, 'message' => $e->getMessage(), 'code' => $e->getCode()]), 500);
    }

    public function dashboardAction()
    {
        $now          = new \DateTime();
        $currentYear  = (int)$now->format('Y');
        $previousYear = $currentYear - 1;
        $currentMonth = (int)$now->format('n');

        return $this->render('perfectstats-dashboard', [
            'current_year'       => $currentYear,
            'previous_year'      => $previousYear,
            'current_month'      => $currentMonth,
            'current_month_name' => $this->getMonthName($currentMonth),
            'current_week'       => (int)$now->format('W'),
            'current_quarter'    => (int)ceil($currentMonth / 3),
            'current_locale'     => $this->getCurrentLocale()
        ]);
    }

    public function getSummaryAction()
    {
        try {
            [$cur, $prev, $y, $py] = $this->getDateRanges();
            return $this->jsonResponse(json_encode(
                $this->perfectStatsService->buildSummary($cur, $prev, $y, $py)
            ));
        } catch (\Exception $e) { return $this->errorResponse($e, 'getSummary'); }
    }

    public function getOrderStatsAction()
    {
        try {
            [$cur, $prev, $y, $py] = $this->getDateRanges();
            $now     = new \DateTime();
            $mode    = $this->getRequest()->query->get('mode', 'month');
            $month   = (int)($this->getRequest()->query->get('month', $now->format('n')));
            $quarter = (int)($this->getRequest()->query->get('quarter', (int)ceil((int)$now->format('n') / 3)));
            [$granularity, $labels] = $this->perfectStatsService->getGranularityForMode($mode, $y, $month, $quarter);
            return $this->jsonResponse(json_encode(
                $this->perfectStatsService->buildOrderStatsForRange($cur, $prev, $y, $py, $granularity, $labels)
            ));
        } catch (\Exception $e) { return $this->errorResponse($e, 'getOrderStats'); }
    }

    public function getRevenueStatsAction()
    {
        try {
            [$cur, $prev, $y, $py] = $this->getDateRanges();
            $now     = new \DateTime();
            $mode    = $this->getRequest()->query->get('mode', 'month');
            $month   = (int)($this->getRequest()->query->get('month', $now->format('n')));
            $quarter = (int)($this->getRequest()->query->get('quarter', (int)ceil((int)$now->format('n') / 3)));
            [$granularity, $labels] = $this->perfectStatsService->getGranularityForMode($mode, $y, $month, $quarter);
            return $this->jsonResponse(json_encode(
                $this->perfectStatsService->buildRevenueStatsForRange($cur, $prev, $y, $py, $granularity, $labels)
            ));
        } catch (\Exception $e) { return $this->errorResponse($e, 'getRevenueStats'); }
    }

    public function getPaymentStatsAction()
    {
        try {
            [$cur, $prev, $y, $py] = $this->getDateRanges();
            return $this->jsonResponse(json_encode(
                $this->perfectStatsService->buildPaymentStats($cur, $prev, $y, $py)
            ));
        } catch (\Exception $e) { return $this->errorResponse($e, 'getPaymentStats'); }
    }

    public function getShippingStatsAction()
    {
        try {
            [$cur, $prev, $y, $py] = $this->getDateRanges();
            return $this->jsonResponse(json_encode(
                $this->perfectStatsService->buildShippingStats($cur, $prev, $y, $py)
            ));
        } catch (\Exception $e) { return $this->errorResponse($e, 'getShippingStats'); }
    }

    public function getProductStatsAction()
    {
        try {
            [$cur, $prev, $y, $py] = $this->getDateRanges();
            return $this->jsonResponse(json_encode(
                $this->perfectStatsService->buildProductStats($cur, $prev, $y, $py)
            ));
        } catch (\Exception $e) { return $this->errorResponse($e, 'getProductStats'); }
    }

    public function getCustomerStatsAction()
    {
        try {
            [$cur, $prev, $y, $py] = $this->getDateRanges();
            return $this->jsonResponse(json_encode(
                $this->perfectStatsService->buildCustomerStats($cur, $prev, $y, $py)
            ));
        } catch (\Exception $e) { return $this->errorResponse($e, 'getCustomerStats'); }
    }

    public function getGeographyStatsAction()
    {
        try {
            [$cur, $prev, $y, $py] = $this->getDateRanges();
            return $this->jsonResponse(json_encode(
                $this->perfectStatsService->buildGeographyStats($cur, $prev, $y, $py, $this->getCurrentLocale())
            ));
        } catch (\Exception $e) { return $this->errorResponse($e, 'getGeographyStats'); }
    }

    public function getBrandStatsAction()
    {
        try {
            [$cur, $prev, $y, $py] = $this->getDateRanges();
            return $this->jsonResponse(json_encode(
                $this->perfectStatsService->buildBrandStats($cur, $prev, $y, $py, $this->getCurrentLocale())
            ));
        } catch (\Exception $e) { return $this->errorResponse($e, 'getBrandStats'); }
    }

    public function getCouponStatsAction()
    {
        try {
            [$cur, $prev, $y, $py] = $this->getDateRanges();
            return $this->jsonResponse(json_encode(
                $this->perfectStatsService->buildCouponStats($cur, $prev, $y, $py)
            ));
        } catch (\Exception $e) { return $this->errorResponse($e, 'getCouponStats'); }
    }
}
