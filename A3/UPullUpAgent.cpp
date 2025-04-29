/*
 * Copyright (c) 2015 - 2025 Intel Corporation
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include "UPullUpAgent.hpp"

#include <cmath>
#include <cassert>
#include <algorithm>
#include <numeric>

#include "geopm/PlatformIO.hpp"
#include "geopm/PlatformTopo.hpp"
#include "geopm/Helper.hpp"
#include "geopm/Agg.hpp"
#include "geopm/Waiter.hpp"
#include "geopm/Environment.hpp"

using geopm::PlatformIO;
using geopm::PlatformTopo;

static void __attribute__((constructor)) upullup_agent_load(void)
{
    geopm::agent_factory().register_plugin(UPullUpAgent::plugin_name(),
                                           UPullUpAgent::make_plugin,
                                           geopm::Agent::make_dictionary(UPullUpAgent::policy_names(),
                                                                         UPullUpAgent::sample_names()));
}

UPullUpAgent::UPullUpAgent()
    : m_platform_io(geopm::platform_io())
    , m_platform_topo(geopm::platform_topo())
    , m_board_power_signal_idx(-1)
    , m_uncore_util_signal_idx(-1)
    , m_uncore_freq_max_control_idx(-1)
    , m_uncore_freq_min_control_idx(-1)
    , m_signal_idx(M_NUM_SAMPLE, -1)
    , m_last_sample(M_NUM_SAMPLE, NAN)
    , m_util_history()
    , m_is_control_active(false)
    , M_WAIT_SEC(1.0)
    , m_waiter(geopm::Waiter::make_unique(geopm::environment().period(M_WAIT_SEC)))
{}

void UPullUpAgent::init(int level, const std::vector<int> &fan_in, bool is_level_root)
{
    // Push signals
    m_board_power_signal_idx = m_platform_io.push_signal("BOARD_POWER_LIMIT_CONTROL", GEOPM_DOMAIN_BOARD, 0);
    m_uncore_util_signal_idx = m_platform_io.push_signal("LEVELZERO::GPU_UNCORE_UTILIZATION", GEOPM_DOMAIN_BOARD, 0);

    m_signal_idx[M_SAMPLE_BOARD_POWER] = m_board_power_signal_idx;
    m_signal_idx[M_SAMPLE_UNCORE_UTIL] = m_uncore_util_signal_idx;

    // Push controls
    if (m_platform_io.control_names().count("CPU_UNCORE_FREQUENCY_MAX_CONTROL") &&
        m_platform_io.control_names().count("CPU_UNCORE_FREQUENCY_MIN_CONTROL")) {

        m_uncore_freq_max_control_idx = m_platform_io.push_control("CPU_UNCORE_FREQUENCY_MAX_CONTROL", GEOPM_DOMAIN_BOARD, 0);
        m_uncore_freq_min_control_idx = m_platform_io.push_control("CPU_UNCORE_FREQUENCY_MIN_CONTROL", GEOPM_DOMAIN_BOARD, 0);
        m_is_control_active = true;
    }
}

void UPullUpAgent::validate_policy(std::vector<double> &in_policy) const
{
    assert(in_policy.size() == M_NUM_POLICY);

    if (std::isnan(in_policy[M_POLICY_POWER_THRESH])) {
        in_policy[M_POLICY_POWER_THRESH] = 2800.0;
    }
    if (std::isnan(in_policy[M_POLICY_UTIL_THRESH])) {
        in_policy[M_POLICY_UTIL_THRESH] = 0.5;
    }
}

void UPullUpAgent::split_policy(const std::vector<double> &in_policy,
                                std::vector<std::vector<double> > &out_policy)
{
    for (auto &child_policy : out_policy) {
        child_policy = in_policy;
    }
}

bool UPullUpAgent::do_send_policy(void) const
{
    return true;
}

void UPullUpAgent::aggregate_sample(const std::vector<std::vector<double> > &in_sample,
                                    std::vector<double> &out_sample)
{
    assert(out_sample.size() == M_NUM_SAMPLE);
    std::vector<double> temp(in_sample.size());

    for (size_t sample_idx = 0; sample_idx < M_NUM_SAMPLE; ++sample_idx) {
        for (size_t i = 0; i < in_sample.size(); ++i) {
            temp[i] = in_sample[i][sample_idx];
        }
        out_sample[sample_idx] = geopm::Agg::average(temp);
    }
}

bool UPullUpAgent::do_send_sample(void) const
{
    return true;
}

void UPullUpAgent::adjust_platform(const std::vector<double> &in_policy)
{
    double P_th = in_policy[M_POLICY_POWER_THRESH];
    double U_th = in_policy[M_POLICY_UTIL_THRESH];
    const double UF_max = 2.3e9; // 2.3 GHz

    if (std::isnan(P_th)) {
        P_th = 2800.0;
    }
    if (std::isnan(U_th)) {
        U_th = 0.5;
    }

    double P_current = m_last_sample[M_SAMPLE_BOARD_POWER];

    if (!m_is_control_active || std::isnan(P_current)) {
        return;
    }

    // Skip adjustment if board power limit exceeds threshold
    if (P_current > P_th) {
        return;
    }

    if (m_util_history.size() == 3) {
        double avg_util = std::accumulate(m_util_history.begin(), m_util_history.end(), 0.0) / 3.0;

        if (avg_util > U_th) {
            m_platform_io.adjust(m_uncore_freq_max_control_idx, UF_max);
            m_platform_io.adjust(m_uncore_freq_min_control_idx, UF_max);
        }
    }
}

bool UPullUpAgent::do_write_batch(void) const
{
    return m_is_control_active;
}

void UPullUpAgent::sample_platform(std::vector<double> &out_sample)
{
    double board_power = m_platform_io.sample(m_board_power_signal_idx);
    double uncore_util = m_platform_io.sample(m_uncore_util_signal_idx);

    m_last_sample[M_SAMPLE_BOARD_POWER] = board_power;
    m_last_sample[M_SAMPLE_UNCORE_UTIL] = uncore_util;

    out_sample[M_SAMPLE_BOARD_POWER] = board_power;
    out_sample[M_SAMPLE_UNCORE_UTIL] = uncore_util;

    if (!std::isnan(uncore_util)) {
        m_util_history.push_back(uncore_util);
        if (m_util_history.size() > 3) {
            m_util_history.pop_front();
        }
    }
}

void UPullUpAgent::wait(void)
{
    m_waiter->wait();
}

std::vector<std::pair<std::string, std::string> > UPullUpAgent::report_header(void) const
{
    return {{"Wait Time (s)", std::to_string(M_WAIT_SEC)}};
}

std::vector<std::pair<std::string, std::string> > UPullUpAgent::report_host(void) const
{
    return {};
}

std::map<uint64_t, std::vector<std::pair<std::string, std::string> > > UPullUpAgent::report_region(void) const
{
    return {};
}

std::vector<std::string> UPullUpAgent::trace_names(void) const
{
    return {"board_power_limit", "uncore_utilization"};
}

void UPullUpAgent::trace_values(std::vector<double> &values)
{
    values[M_TRACE_VAL_BOARD_POWER] = m_last_sample[M_SAMPLE_BOARD_POWER];
    values[M_TRACE_VAL_UNCORE_UTIL] = m_last_sample[M_SAMPLE_UNCORE_UTIL];
}

std::vector<std::function<std::string(double)> > UPullUpAgent::trace_formats(void) const
{
    return {geopm::string_format_float, geopm::string_format_float};
}

void UPullUpAgent::enforce_policy(const std::vector<double> &policy) const
{
}

std::string UPullUpAgent::plugin_name(void)
{
    return "upullup";
}

std::unique_ptr<geopm::Agent> UPullUpAgent::make_plugin(void)
{
    return geopm::make_unique<UPullUpAgent>();
}

std::vector<std::string> UPullUpAgent::policy_names(void)
{
    return {"POWER_THRESHOLD", "UNCORE_UTILIZATION_THRESHOLD"};
}

std::vector<std::string> UPullUpAgent::sample_names(void)
{
    return {"BOARD_POWER_LIMIT", "UNCORE_UTILIZATION"};
}

