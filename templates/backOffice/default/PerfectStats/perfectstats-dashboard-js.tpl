{literal}
(function($) {
    'use strict';

    var currentYear      = PERFECTSTATS_YEARS.current;
    var previousYear     = PERFECTSTATS_YEARS.previous;
    var currentMonth     = PERFECTSTATS_YEARS.currentMonth;
    var currentMonthName = PERFECTSTATS_YEARS.currentMonthName;
    var currentWeek      = PERFECTSTATS_YEARS.currentWeek;
    var currentQuarter   = PERFECTSTATS_YEARS.currentQuarter;
    var currentMode      = 'month';
    var charts = {};
    
    var COLORS = ['#337ab7','#5cb85c','#d9534f','#f0ad4e','#5bc0de','#9b59b6','#1abc9c','#e67e22','#e74c3c','#3498db','#2ecc71','#f39c12','#8e44ad','#16a085','#d35400'];

    function formatCurrency(amount) { return new Intl.NumberFormat('fr-FR', {style:'currency',currency:'EUR'}).format(amount); }
    function formatPct(v) { return (v > 0 ? '+' : '') + parseFloat(v).toFixed(1) + '%'; }
    function formatPercentage(v) { return formatPct(v); }
    function destroyChart(id) { if (charts[id]) { charts[id].destroy(); delete charts[id]; } }
    function handleAjaxError(xhr, status, error, name) { console.error('PerfectStats API Error (' + name + '):', {status: xhr.status, ajaxStatus: status, error: error, response: xhr.responseText}); }

    // ── Period params ──────────────────────────────────────────────────────────
    function buildApiParams() {
        var p = '?mode=' + currentMode + '&year=' + currentYear;
        if (currentMode === 'month')   p += '&month='   + currentMonth;
        if (currentMode === 'week')    p += '&week='    + currentWeek;
        if (currentMode === 'quarter') p += '&quarter=' + currentQuarter;
        if (currentMode === 'day') { var n = new Date(); p += '&month=' + (n.getMonth()+1) + '&day=' + n.getDate(); }
        return p;
    }
    
    function createPieChart(canvasId, labels, data) {
        destroyChart(canvasId);
        var ctx = document.getElementById(canvasId);
        if (!ctx || data.length === 0) return;
        charts[canvasId] = new Chart(ctx.getContext('2d'), {type: 'doughnut', data: {labels: labels, datasets: [{data: data, backgroundColor: COLORS.slice(0, data.length), borderWidth: 2, borderColor: '#fff'}]}, options: {responsive: true, maintainAspectRatio: false, plugins: {legend: {position: 'right', labels: {boxWidth: 12}}}}});
    }
    
    function getPeriodLabels() {
        var cur, prev;
        switch (currentMode) {
            case 'day':     var n = new Date(); cur = n.toLocaleDateString('fr-FR') + ' ' + currentYear; prev = n.toLocaleDateString('fr-FR') + ' ' + previousYear; break;
            case 'week':    cur = 'S' + currentWeek    + ' ' + currentYear; prev = 'S' + currentWeek    + ' ' + previousYear; break;
            case 'quarter': cur = 'T' + currentQuarter + ' ' + currentYear; prev = 'T' + currentQuarter + ' ' + previousYear; break;
            case 'month':   cur = currentMonthName + ' ' + currentYear;     prev = currentMonthName + ' ' + previousYear; break;
            default:        cur = currentYear.toString(); prev = previousYear.toString();
        }
        return {current: cur, previous: prev};
    }

    function updatePeriodLabels() {
        var lbl = getPeriodLabels();
        var vs = ' ' + PERFECTSTATS_LABELS.vs + ' ';
        var pt;
        switch (currentMode) {
            case 'day':     pt = PERFECTSTATS_LABELS.periodDay     + ' : ' + lbl.current + vs + lbl.previous; break;
            case 'week':    pt = PERFECTSTATS_LABELS.periodWeek    + ' : ' + lbl.current + vs + lbl.previous; break;
            case 'quarter': pt = PERFECTSTATS_LABELS.periodQuarter + ' : ' + lbl.current + vs + lbl.previous; break;
            case 'month':   pt = PERFECTSTATS_LABELS.periodMonth   + ' : ' + lbl.current + vs + lbl.previous; break;
            default:        pt = PERFECTSTATS_LABELS.periodYear    + ' : ' + lbl.current + vs + lbl.previous;
        }
        $('#period-label').text(pt);
        $('#payments-th-current,#shipping-th-current,#geo-th-current').text(lbl.current);
        $('#payments-th-previous,#shipping-th-previous,#geo-th-previous').text(lbl.previous);
        $('#payments-chart-current-title,#shipping-chart-current-title,#geo-chart-current-title').text(lbl.current);
        $('#payments-chart-previous-title,#shipping-chart-previous-title,#geo-chart-previous-title').text(lbl.previous);
        $('#products-current-title').text(PERFECTSTATS_LABELS.topProducts + ' (' + lbl.current + ')');
        $('#products-previous-title').text(PERFECTSTATS_LABELS.topProducts + ' (' + lbl.previous + ')');
        $('#customers-current-title').text(PERFECTSTATS_LABELS.topCustomers + ' (' + lbl.current + ')');
        $('#customers-previous-title').text(PERFECTSTATS_LABELS.topCustomers + ' (' + lbl.previous + ')');
        $('#brands-current-title').text(PERFECTSTATS_LABELS.topBrands + ' (' + lbl.current + ')');
        $('#brands-previous-title').text(PERFECTSTATS_LABELS.topBrands + ' (' + lbl.previous + ')');
        $('#coupons-current-title').text(lbl.current);
        $('#coupons-previous-title').text(lbl.previous);
    }

    function getDropdownLabel() {
        switch (currentMode) {
            case 'day':     var n = new Date(); return '<span class="fa fa-sun-o"></span> ' + PERFECTSTATS_LABELS.day     + ' — ' + n.toLocaleDateString('fr-FR');
            case 'week':    return '<span class="fa fa-calendar-o"></span> ' + PERFECTSTATS_LABELS.week    + ' — S' + currentWeek    + ' ' + currentYear;
            case 'quarter': return '<span class="fa fa-pie-chart"></span> '  + PERFECTSTATS_LABELS.quarter + ' — T' + currentQuarter + ' ' + currentYear;
            case 'month':   return '<span class="fa fa-calendar"></span> '   + PERFECTSTATS_LABELS.month   + ' — ' + currentMonthName + ' ' + currentYear;
            default:        return '<span class="fa fa-line-chart"></span> '  + PERFECTSTATS_LABELS.year    + ' ' + currentYear;
        }
    }
    
    function loadSummary() {
        $.ajax({url: PERFECTSTATS_URLS.summary + buildApiParams(), method: 'GET', dataType: 'json', success: function(data) {
            $('#stat-total-amount').text(formatCurrency(data.current.total_amount));
            $('#stat-order-count').text(data.current.order_count);
            $('#stat-sent-count').text(data.current.sent_count);
            $('#stat-cancelled-count').text(data.current.cancelled_count);
            $('#stat-avg-order').text(formatCurrency(data.current.average_order));
            $('#stat-cancel-rate').text(data.current.cancellation_rate + '%');
            var labels = getPeriodLabels();
            $('#prev-total-amount').text(labels.previous + ': ' + formatCurrency(data.previous.total_amount));
            $('#prev-order-count').text(labels.previous + ': ' + data.previous.order_count);
            $('#prev-sent-count').text(labels.previous + ': ' + data.previous.sent_count);
            $('#prev-cancelled-count').text(labels.previous + ': ' + data.previous.cancelled_count);
            $('#prev-avg-order').text(labels.previous + ': ' + formatCurrency(data.previous.average_order));
            $('#prev-cancel-rate').text(labels.previous + ': ' + data.previous.cancellation_rate + '%');
            function setEvo(id, v) { $('#' + id).text(formatPct(v)).removeClass('positive negative').addClass(v >= 0 ? 'positive' : 'negative'); }
            setEvo('evolution-total-amount', data.evolution.total_amount);
            setEvo('evolution-order-count', data.evolution.order_count);
            setEvo('evolution-sent-count', data.evolution.sent_count);
            setEvo('evolution-cancelled-count', data.evolution.cancelled_count);
            setEvo('evolution-avg-order', data.evolution.average_order);
        }, error: function(xhr, status, error) { handleAjaxError(xhr, status, error, 'summary'); }});
    }
    
    function loadOrdersChart() {
        var params = buildApiParams();
        $.ajax({url: PERFECTSTATS_URLS.orders + params, method: 'GET', dataType: 'json', success: function(data) {
            destroyChart('ordersChart');
            var ctx = document.getElementById('ordersChart');
            if (!ctx) return;
            var labels = getPeriodLabels();
            charts['ordersChart'] = new Chart(ctx.getContext('2d'), {type: 'bar', data: {labels: data.labels, datasets: [{label: labels.current + ' — ' + PERFECTSTATS_LABELS.sent, data: data.current.sent, backgroundColor: 'rgba(92, 184, 92, 0.7)', borderColor: 'rgba(92, 184, 92, 1)', borderWidth: 1}, {label: labels.previous + ' — ' + PERFECTSTATS_LABELS.sent, data: data.previous.sent, backgroundColor: 'rgba(92, 184, 92, 0.3)', borderColor: 'rgba(92, 184, 92, 0.6)', borderWidth: 1}, {label: labels.current + ' — ' + PERFECTSTATS_LABELS.cancelled, data: data.current.cancelled, backgroundColor: 'rgba(217, 83, 79, 0.7)', borderColor: 'rgba(217, 83, 79, 1)', borderWidth: 1}, {label: labels.previous + ' — ' + PERFECTSTATS_LABELS.cancelled, data: data.previous.cancelled, backgroundColor: 'rgba(217, 83, 79, 0.3)', borderColor: 'rgba(217, 83, 79, 0.6)', borderWidth: 1}]}, options: {responsive: true, maintainAspectRatio: false, plugins: {legend: {position: 'top'}}, scales: {y: {beginAtZero: true, ticks: {stepSize: 1}}}}});
        }, error: function(xhr, status, error) { handleAjaxError(xhr, status, error, 'orders'); }});
        
        $.ajax({url: PERFECTSTATS_URLS.revenue + params, method: 'GET', dataType: 'json', success: function(data) {
            destroyChart('revenueChart');
            var ctx = document.getElementById('revenueChart');
            if (!ctx) return;
            var labels = getPeriodLabels();
            charts['revenueChart'] = new Chart(ctx.getContext('2d'), {type: 'line', data: {labels: data.labels, datasets: [{label: labels.current, data: data.current, borderColor: '#337ab7', backgroundColor: 'rgba(51, 122, 183, 0.1)', borderWidth: 2, fill: true, tension: 0.3}, {label: labels.previous, data: data.previous, borderColor: '#5bc0de', backgroundColor: 'rgba(91, 192, 222, 0.1)', borderWidth: 2, borderDash: [5, 5], fill: true, tension: 0.3}]}, options: {responsive: true, maintainAspectRatio: false, plugins: {legend: {position: 'top'}}, scales: {y: {beginAtZero: true, ticks: {callback: function(v) { return new Intl.NumberFormat('fr-FR', {style: 'currency', currency: 'EUR', maximumFractionDigits: 0}).format(v); }}}}}});
        }, error: function(xhr, status, error) { handleAjaxError(xhr, status, error, 'revenue'); }});
    }
    
    function loadPaymentStats() {
        $.ajax({url: PERFECTSTATS_URLS.payments + buildApiParams(), method: 'GET', dataType: 'json', success: function(data) {
            var tbody = $('#payments-table tbody');
            tbody.empty();
            var currentLabels = [], currentData = [], previousLabels = [], previousData = [];
            $.each(data.current, function(method, val) { currentLabels.push(method); currentData.push(val.count); });
            $.each(data.previous, function(method, val) { previousLabels.push(method); previousData.push(val.count); });
            createPieChart('paymentsChartCurrent', currentLabels, currentData);
            createPieChart('paymentsChartPrevious', previousLabels, previousData);
            var allMethods = {};
            $.each(data.current, function(k) { allMethods[k] = true; });
            $.each(data.previous, function(k) { allMethods[k] = true; });
            $.each(allMethods, function(method) {
                var current = data.current[method] || {count: 0, amount: 0};
                var previous = data.previous[method] || {count: 0, amount: 0};
                var evolution = previous.count > 0 ? ((current.count - previous.count) / previous.count) * 100 : 0;
                tbody.append('<tr><td>' + method + '</td><td>'  + current.count + ' (' + formatCurrency(current.amount) + ')</td><td>' + previous.count + ' (' + formatCurrency(previous.amount) + ')</td><td class="' + (evolution >= 0 ? 'positive' : 'negative') + '">' + formatPercentage(evolution) + '</td></tr>');
            });
            if (tbody.children().length === 0) tbody.append('<tr><td colspan="4" class="text-center text-muted">' + PERFECTSTATS_LABELS.noData + '</td></tr>');
        }, error: function(xhr, status, error) { handleAjaxError(xhr, status, error, 'payments'); }});
    }
    
    function loadShippingStats() {
        $.ajax({url: PERFECTSTATS_URLS.shipping + buildApiParams(), method: 'GET', dataType: 'json', success: function(data) {
            var tbody = $('#shipping-table tbody');
            tbody.empty();
            var currentLabels = [], currentData = [], previousLabels = [], previousData = [];
            $.each(data.current, function(method, val) { currentLabels.push(method); currentData.push(val.count); });
            $.each(data.previous, function(method, val) { previousLabels.push(method); previousData.push(val.count); });
            createPieChart('shippingChartCurrent', currentLabels, currentData);
            createPieChart('shippingChartPrevious', previousLabels, previousData);
            var allMethods = {};
            $.each(data.current, function(k) { allMethods[k] = true; });
            $.each(data.previous, function(k) { allMethods[k] = true; });
            $.each(allMethods, function(method) {
                var current = data.current[method] || {count: 0, amount: 0};
                var previous = data.previous[method] || {count: 0, amount: 0};
                var evolution = previous.count > 0 ? ((current.count - previous.count) / previous.count) * 100 : 0;
                tbody.append('<tr><td>' + method + '</td><td>' + current.count + ' (' + formatCurrency(current.amount) + ')</td><td>' + previous.count + ' (' + formatCurrency(previous.amount) + ')</td><td class="' + (evolution >= 0 ? 'positive' : 'negative') + '">' + formatPercentage(evolution) + '</td></tr>');
            });
            if (tbody.children().length === 0) tbody.append('<tr><td colspan="4" class="text-center text-muted">' + PERFECTSTATS_LABELS.noData + '</td></tr>');
        }, error: function(xhr, status, error) { handleAjaxError(xhr, status, error, 'shipping'); }});
    }
    
    function loadProductStats() {
        $.ajax({url: PERFECTSTATS_URLS.products + buildApiParams(), method: 'GET', dataType: 'json', success: function(data) {
            var tbody = $('#products-table tbody');
            tbody.empty();
            var rank = 1;
            var currentLabels = [], currentQty = [], previousQty = [];
            $.each(data.top_products, function(index, product) {
                tbody.append('<tr><td><strong>' + rank + '</strong></td><td>' + product.name + '<br><small class="text-muted">' + product.ref + '</small></td><td>' + product.quantity + '</td><td>' + formatCurrency(product.amount) + '</td></tr>');
                currentLabels.push(product.name.substring(0, 20));
                currentQty.push(product.quantity);
                rank++;
            });
            if (tbody.children().length === 0) tbody.append('<tr><td colspan="4" class="text-center text-muted">' + PERFECTSTATS_LABELS.noData + '</td></tr>');
            var tbodyPrev = $('#products-prev-table tbody');
            tbodyPrev.empty();
            rank = 1;
            $.each(data.previous_top_products, function(index, product) {
                tbodyPrev.append('<tr><td><strong>' + rank + '</strong></td><td>' + product.name + '<br><small class="text-muted">' + product.ref + '</small></td><td>' + product.quantity + '</td><td>' + formatCurrency(product.amount) + '</td></tr>');
                previousQty.push(product.quantity);
                rank++;
            });
            if (tbodyPrev.children().length === 0) tbodyPrev.append('<tr><td colspan="4" class="text-center text-muted">' + PERFECTSTATS_LABELS.noData + '</td></tr>');
            destroyChart('productsChart');
            var ctx = document.getElementById('productsChart');
            if (ctx && currentLabels.length > 0) {
                var labels = getPeriodLabels();
                charts['productsChart'] = new Chart(ctx.getContext('2d'), {type: 'bar', data: {labels: currentLabels, datasets: [{label: labels.current, data: currentQty, backgroundColor: 'rgba(51, 122, 183, 0.7)', borderColor: '#337ab7', borderWidth: 1}, {label: labels.previous, data: previousQty, backgroundColor: 'rgba(91, 192, 222, 0.5)', borderColor: '#5bc0de', borderWidth: 1}]}, options: {responsive: true, maintainAspectRatio: false, plugins: {legend: {position: 'top'}}, scales: {y: {beginAtZero: true}}}});
            }
        }, error: function(xhr, status, error) { handleAjaxError(xhr, status, error, 'products'); }});
    }
    
    function loadCustomerStats() {
        $.ajax({url: PERFECTSTATS_URLS.customers + buildApiParams(), method: 'GET', dataType: 'json', success: function(data) {
            $('#stat-new-customers').text(data.new_customers.current);
            var labels = getPeriodLabels();
            $('#prev-new-customers').text(labels.previous + ': ' + data.new_customers.previous);
            $('#evolution-new-customers').text(formatPercentage(data.new_customers.evolution)).removeClass('positive negative').addClass(data.new_customers.evolution >= 0 ? 'positive' : 'negative');
            var tbody = $('#customers-table tbody');
            tbody.empty();
            var rank = 1;
            $.each(data.top_customers, function(id, customer) {
                var name = customer.firstname + ' ' + customer.lastname;
                tbody.append('<tr><td><strong>' + rank + '</strong></td><td>' + name + '<br><small class="text-muted">' + customer.email + '</small></td><td>' + customer.order_count + '</td><td>' + formatCurrency(customer.total_amount) + '</td></tr>');
                rank++;
            });
            if (tbody.children().length === 0) tbody.append('<tr><td colspan="4" class="text-center text-muted">' + PERFECTSTATS_LABELS.noData + '</td></tr>');
            var tbodyPrev = $('#customers-prev-table tbody');
            tbodyPrev.empty();
            rank = 1;
            $.each(data.previous_top_customers, function(id, customer) {
                var name = customer.firstname + ' ' + customer.lastname;
                tbodyPrev.append('<tr><td><strong>' + rank + '</strong></td><td>' + name + '<br><small class="text-muted">' + customer.email + '</small></td><td>' + customer.order_count + '</td><td>' + formatCurrency(customer.total_amount) + '</td></tr>');
                rank++;
            });
            if (tbodyPrev.children().length === 0) tbodyPrev.append('<tr><td colspan="4" class="text-center text-muted">' + PERFECTSTATS_LABELS.noData + '</td></tr>');
        }, error: function(xhr, status, error) { handleAjaxError(xhr, status, error, 'customers'); }});
    }
    
    function loadGeographyStats() {
        $.ajax({url: PERFECTSTATS_URLS.geography + buildApiParams(), method: 'GET', dataType: 'json', success: function(data) {
            var tbody = $('#country-table tbody');
            tbody.empty();
            var currentLabels = [], currentData = [], previousLabels = [], previousData = [];
            $.each(data.current, function(id, country) { currentLabels.push(country.name); currentData.push(country.order_count); });
            $.each(data.previous, function(id, country) { previousLabels.push(country.name); previousData.push(country.order_count); });
            createPieChart('geoChartCurrent', currentLabels, currentData);
            createPieChart('geoChartPrevious', previousLabels, previousData);
            var mergedCountries = {};
            $.each(data.current, function(id, country) {
                mergedCountries[id] = {name: country.name, flag: country.flag || '', current: country, previous: data.previous[id] || {order_count: 0, total_amount: 0}};
            });
            $.each(data.previous, function(id, country) {
                if (!mergedCountries[id]) mergedCountries[id] = {name: country.name, flag: country.flag || '', current: {order_count: 0, total_amount: 0}, previous: country};
            });
            var sortedCountries = Object.values(mergedCountries).sort(function(a, b) { return b.current.total_amount - a.current.total_amount; });
            var rank = 1;
            $.each(sortedCountries, function(i, item) {
                var evolution = item.previous.order_count > 0 ? ((item.current.order_count - item.previous.order_count) / item.previous.order_count) * 100 : 0;
                var evoText = item.previous.order_count > 0 ? '<span class="' + (evolution >= 0 ? 'positive' : 'negative') + '">' + formatPercentage(evolution) + '</span>' : (item.current.order_count > 0 ? '<span class="text-success">Nouveau</span>' : '--');
                var countryDisplay = item.flag ? item.flag + ' ' + item.name : item.name;
                tbody.append('<tr><td><strong>' + rank + '</strong></td><td>' + countryDisplay + '</td><td>' + item.current.order_count + (item.current.order_count > 0 ? ' (' + formatCurrency(item.current.total_amount) + ')' : '') + '</td><td>' + item.previous.order_count + (item.previous.order_count > 0 ? ' (' + formatCurrency(item.previous.total_amount) + ')' : '') + '</td><td>' + evoText + '</td></tr>');
                rank++;
            });
            if (tbody.children().length === 0) tbody.append('<tr><td colspan="5" class="text-center text-muted">' + PERFECTSTATS_LABELS.noData + '</td></tr>');
        }, error: function(xhr, status, error) { handleAjaxError(xhr, status, error, 'geography'); }});
    }
    
    function loadBrandStats() {
        $.ajax({url: PERFECTSTATS_URLS.brands + buildApiParams(), method: 'GET', dataType: 'json', success: function(data) {
            var lbl = getPeriodLabels();
            var tbody = $('#brands-table tbody').empty(); var rank = 1;
            var cLabels = [], cQty = [], pQty = [];
            $.each(data.current, function(i, b) {
                tbody.append('<tr><td><strong>' + rank + '</strong></td><td>' + b.name + '</td><td>' + b.quantity + '</td><td>' + formatCurrency(b.amount) + '</td></tr>');
                cLabels.push(b.name.substring(0,20)); cQty.push(b.quantity); rank++;
            });
            if (!tbody.children().length) tbody.append('<tr><td colspan="4" class="text-center text-muted">' + PERFECTSTATS_LABELS.noData + '</td></tr>');
            var tbodyP = $('#brands-prev-table tbody').empty(); rank = 1;
            $.each(data.previous, function(i, b) {
                tbodyP.append('<tr><td><strong>' + rank + '</strong></td><td>' + b.name + '</td><td>' + b.quantity + '</td><td>' + formatCurrency(b.amount) + '</td></tr>');
                pQty.push(b.quantity); rank++;
            });
            if (!tbodyP.children().length) tbodyP.append('<tr><td colspan="4" class="text-center text-muted">' + PERFECTSTATS_LABELS.noData + '</td></tr>');
            destroyChart('brandsChart');
            var ctx = document.getElementById('brandsChart');
            if (ctx && cLabels.length) {
                charts['brandsChart'] = new Chart(ctx.getContext('2d'), {
                    type: 'bar',
                    data: {labels: cLabels, datasets: [
                        {label: lbl.current,  data: cQty, backgroundColor: 'rgba(155,89,182,0.7)', borderColor: '#9b59b6', borderWidth: 1},
                        {label: lbl.previous, data: pQty, backgroundColor: 'rgba(155,89,182,0.3)', borderColor: '#9b59b6', borderWidth: 1}
                    ]},
                    options: {responsive: true, maintainAspectRatio: false, plugins: {legend: {position: 'top'}}, scales: {y: {beginAtZero: true}}}
                });
            }
        }, error: function(xhr, s, e) { handleAjaxError(xhr, s, e, 'brands'); }});
    }

    function loadCouponStats() {
        $.ajax({url: PERFECTSTATS_URLS.coupons + buildApiParams(), method: 'GET', dataType: 'json', success: function(data) {
            var tbody = $('#coupons-table tbody').empty(); var rank = 1;
            $.each(data.current, function(i, c) {
                tbody.append('<tr><td><strong>' + rank + '</strong></td><td><code>' + c.code + '</code></td><td>' + c.usage_count + '</td><td>' + formatCurrency(c.total_discount) + '</td><td>' + c.total_orders + '</td></tr>');
                rank++;
            });
            if (!tbody.children().length) tbody.append('<tr><td colspan="5" class="text-center text-muted">' + PERFECTSTATS_LABELS.noData + '</td></tr>');
            var tbodyP = $('#coupons-prev-table tbody').empty(); rank = 1;
            $.each(data.previous, function(i, c) {
                tbodyP.append('<tr><td><strong>' + rank + '</strong></td><td><code>' + c.code + '</code></td><td>' + c.usage_count + '</td><td>' + formatCurrency(c.total_discount) + '</td><td>' + c.total_orders + '</td></tr>');
                rank++;
            });
            if (!tbodyP.children().length) tbodyP.append('<tr><td colspan="5" class="text-center text-muted">' + PERFECTSTATS_LABELS.noData + '</td></tr>');
        }, error: function(xhr, s, e) { handleAjaxError(xhr, s, e, 'coupons'); }});
    }

    function loadAllStats() {
        updatePeriodLabels();
        loadSummary();
        loadOrdersChart();
        loadPaymentStats();
        loadShippingStats();
        loadProductStats();
        loadCustomerStats();
        loadGeographyStats();
        loadBrandStats();
        loadCouponStats();
    }

    $(document).ready(function() {
        loadAllStats();

        $(document).on('click', function(e) {
            if (!$(e.target).closest('.period-dropdown-wrapper').length) $('#period-dropdown-menu').removeClass('open');
        });
        $('#period-dropdown-btn').on('click', function(e) {
            e.stopPropagation();
            $('#period-dropdown-menu').toggleClass('open');
        });
        $('.period-option').on('click', function() {
            var mode = $(this).data('mode');
            $('#period-dropdown-menu').removeClass('open');
            if (currentMode === mode) return;
            currentMode = mode;
            $('.period-option').removeClass('active');
            $(this).addClass('active');
            $('#period-btn-label').html(getDropdownLabel());
            loadAllStats();
        });

        $('a[data-toggle="tab"]').on('shown.bs.tab', function() {
            setTimeout(function() { $.each(charts, function(id, c) { if (c) c.resize(); }); }, 200);
        });
    });
})(jQuery);
{/literal}