source("plots/include.R")

OUT <- ARGS[1]
DIR <- ARGS[2]
ARCHIVE <- ARGS[3]

df <- read_from_archive(DIR, ARCHIVE, .rm = TRUE)

data.latency <- df$latency %>%
    group_by(id, stat_name) %>%
    summarise_mean(stat_value)

data.speed <- df$latency_ts %>%
    group_by(id, run, host_address) %>%
    summarise(count = max(count), duration = max(time), .groups = "drop") %>%
    group_by(id, run) %>%
    summarise(count = sum(count), duration = max(duration), speed = duration / count, .groups = "drop") %>%
    group_by(id) %>%
    summarise_mean(speed)

format_data_latency <- function(.data) {
    stats.levels <- c("mean", "p50", "p90", "p99.0")
    stats.labels <- c("Mean", "Median", "P90", "P99")

    config.levels <- c("xp1/cassandra-base.yaml", "xp1/cassandra-se.yaml")
    config.labels <- c("Cassandra", "Hector")

    rate.levels <- c("fixed=200000", "fixed=500000")
    rate.labels <- c("200 kops/s", "500 kops/s")

    .data %>%
        inner_join(df$input, by = "id") %>%
        filter(stat_name %in% stats.levels, main_rate_limit %in% rate.levels) %>%
        mutate(stat_name = factor(stat_name, levels = stats.levels, labels = stats.labels),
               config_file = factor(config_file, levels = config.levels, labels = config.labels),
               main_rate_limit = factor(main_rate_limit, levels = rate.levels, labels = rate.labels))
}

tikz(file = paste0(OUT, "/xp1_latency.tex"), width = 2.9, height = 1.7)

plot.xp1.latency <- ggplot(data = format_data_latency(data.latency)) +
    geom_col(mapping = aes(x = config_file,
                           y = mean_stat_value * NANOS_TO_MILLIS,
                           fill = config_file),
             width = 0.4) +
    geom_errorbar(mapping = aes(x = config_file,
                                ymin = mean_low_stat_value * NANOS_TO_MILLIS,
                                ymax = mean_high_stat_value * NANOS_TO_MILLIS),
                  width = 0.1) +
    facet_grid(rows = vars(main_rate_limit),
               cols = vars(stat_name),
               scales = "free") +
    coord_cartesian(ylim = c(0, NA)) +
    scale_x_discrete(name = "Version") +
    scale_y_continuous(name = "Latency (ms)") +
    scale_fill_discrete(name = "Version", guide = "none") +
    theme_bw() +
    theme(axis.title.x = element_blank(),
          axis.text.x = element_text(angle = 20, hjust = 0.8, vjust = 1))

update_theme_for_latex(plot.xp1.latency)

dev.off()

format_data_speed <- function(.data) {
    config.levels <- c("xp1/cassandra-base.yaml", "xp1/cassandra-se.yaml")
    config.labels <- c("Cassandra", "Hector")

    .data %>%
        inner_join(df$input, by = "id") %>%
        filter(id %in% c("xp1_5", "xp1_6")) %>%
        mutate(config_file = factor(config_file, levels = config.levels, labels = config.labels))
}

tikz(file = paste0(OUT, "/xp1_throughput.tex"), width = 1.4, height = 1.2)

plot.xp1.throughput <- ggplot(data = format_data_speed(data.speed)) +
    geom_col(mapping = aes(x = config_file,
                           y = 1 / mean_speed * OPSS_TO_KOPSS,
                           fill = config_file),
             width = 0.4) +
    geom_errorbar(mapping = aes(x = config_file,
                                ymin = 1 / mean_high_speed * OPSS_TO_KOPSS,
                                ymax = 1 / mean_low_speed * OPSS_TO_KOPSS),
                  width = 0.1) +
    coord_cartesian(ylim = c(0, NA)) +
    scale_x_discrete(name = "Version") +
    scale_y_continuous(name = "Throughput (kops/s)") +
    scale_fill_discrete(name = "Version", guide = "none") +
    theme_bw() +
    theme(axis.title.x = element_blank())

update_theme_for_latex(plot.xp1.throughput)

dev.off()
