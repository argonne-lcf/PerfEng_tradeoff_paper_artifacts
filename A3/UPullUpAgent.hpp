#ifndef UPULLUPAGENT_HPP_INCLUDE
#define UPULLUPAGENT_HPP_INCLUDE

#include <vector>
#include <deque>

#include "geopm/Agent.hpp"
#include "geopm_time.h"

namespace geopm
{
    class PlatformTopo;
    class PlatformIO;
    class Waiter;
}

/// @brief U-PullUp Agent: Utilization-aware Uncore Frequency Booster
class UPullUpAgent : public geopm::Agent
{
    public:
        UPullUpAgent();
        virtual ~UPullUpAgent() = default;
        void init(int level, const std::vector<int> &fan_in, bool is_level_root) override;
        void validate_policy(std::vector<double> &in_policy) const override;
        void split_policy(const std::vector<double> &in_policy,
                          std::vector<std::vector<double> > &out_policy) override;
        bool do_send_policy(void) const override;
        void aggregate_sample(const std::vector<std::vector<double> > &in_sample,
                              std::vector<double> &out_sample) override;
        bool do_send_sample(void) const override;
        void adjust_platform(const std::vector<double> &in_policy) override;
        bool do_write_batch(void) const override;
        void sample_platform(std::vector<double> &out_sample) override;
        void wait(void) override;
        std::vector<std::pair<std::string, std::string> > report_header(void) const override;
        std::vector<std::pair<std::string, std::string> > report_host(void) const override;
        std::map<uint64_t, std::vector<std::pair<std::string, std::string> > > report_region(void) const override;
        std::vector<std::string> trace_names(void) const override;
        void trace_values(std::vector<double> &values) override;
        std::vector<std::function<std::string(double)> > trace_formats(void) const override;
        void enforce_policy(const std::vector<double> &policy) const override;

        static std::string plugin_name(void);
        static std::unique_ptr<geopm::Agent> make_plugin(void);
        static std::vector<std::string> policy_names(void);
        static std::vector<std::string> sample_names(void);
    private:
        enum m_policy_e {
            M_POLICY_POWER_THRESH,
            M_POLICY_UTIL_THRESH,
            M_NUM_POLICY
        };
        enum m_sample_e {
            M_SAMPLE_BOARD_POWER,
            M_SAMPLE_UNCORE_UTIL,
            M_NUM_SAMPLE
        };
        enum m_trace_value_e {
            M_TRACE_VAL_BOARD_POWER,
            M_TRACE_VAL_UNCORE_UTIL,
            M_NUM_TRACE_VAL
        };

        geopm::PlatformIO &m_platform_io;
        const geopm::PlatformTopo &m_platform_topo;

        int m_board_power_signal_idx;
        int m_uncore_util_signal_idx;
        int m_uncore_freq_max_control_idx;
        int m_uncore_freq_min_control_idx;

        std::vector<int> m_signal_idx;
        std::vector<double> m_last_sample;

        std::deque<double> m_util_history;

        bool m_is_control_active;
        const double M_WAIT_SEC;
        std::unique_ptr<geopm::Waiter> m_waiter;
};

#endif

