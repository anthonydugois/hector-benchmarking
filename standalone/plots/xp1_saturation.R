source("standalone/plots/include.R")

OUT <- ARGS[1]
DIR <- ARGS[2]
ARCHIVE <- ARGS[3]

df <- read_from_archive(DIR, ARCHIVE, .rm = TRUE)

data.speed <- df$latency_ts %>%
    group_by(id, run, host_address) %>%
    summarise(count = max(count), duration = max(time), .groups = "drop") %>%
    group_by(id, run) %>%
    summarise(count = sum(count), duration = max(duration), speed = duration / count, .groups = "drop") %>%
    group_by(id) %>%
    summarise_mean(speed)

format_data <- function(.data) {
    config.levels <- c("xp0/cassandra-base.yaml", "xp0/cassandra-se.yaml")
    config.labels <- c("Cassandra", "Hector")

    .data %>%
        inner_join(df$input, by = "id") %>%
        filter(id %in% c("xp0_5", "xp0_6")) %>%
        mutate(config_file = factor(config_file, levels = config.levels, labels = config.labels))
}

tikz(file = paste0(OUT, "/xp1_throughput.tex"), width = 1.4, height = 1.2)

plot.xp0.throughput <- ggplot(data = format_data(data.speed)) +
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

update_theme_for_latex(plot.xp0.throughput)

dev.off()
