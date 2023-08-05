source("standalone/plots/include.R")

OUT <- ARGS[1]
DIR <- ARGS[2]
ARCHIVE <- ARGS[3]

df <- read_from_archive(DIR, ARCHIVE, .rm = TRUE)

data.latency <- df$latency %>%
    group_by(id, stat_name) %>%
    summarise_mean(stat_value)

format_data <- function(.data) {
    stats.levels <- c("mean", "p50", "p90", "p99.0")
    stats.labels <- c("Mean", "Median", "P90", "P99")

    config.levels <- c("xp0/cassandra-base.yaml", "xp0/cassandra-se.yaml")
    config.labels <- c("Cassandra", "Hector")

    rate.levels <- c("fixed=200000", "fixed=500000")
    rate.labels <- c("200 kops/s", "500 kops/s")

    .data %>%
        inner_join(df$input, by = "id") %>%
        filter(stat_name %in% stats.levels) %>%
        mutate(stat_name = factor(stat_name, levels = stats.levels, labels = stats.labels),
               config_file = factor(config_file, levels = config.levels, labels = config.labels),
               main_rate_limit = factor(main_rate_limit, levels = rate.levels, labels = rate.labels))
}

tikz(file = paste0(OUT, "/xp1_latency.tex"), width = 2.9, height = 1.7)

plot.xp0.latency <- ggplot(data = format_data(data.latency)) +
    geom_col(mapping = aes(x = config_file,
                           y = mean_stat_value * NANOS_TO_MILLIS,
                           fill = config_file),
             width = 0.4,
             colour = "black") +
    geom_errorbar(mapping = aes(x = config_file,
                                ymin = mean_low_stat_value * NANOS_TO_MILLIS,
                                ymax = mean_high_stat_value * NANOS_TO_MILLIS),
                  width = 0.1,
                  colour = "black") +
    facet_grid(rows = vars(main_rate_limit),
               cols = vars(stat_name),
               scales = "free") +
    coord_cartesian(ylim = c(0, NA)) +
    scale_x_discrete(name = "Version") +
    scale_y_continuous(name = "Latency (ms)") +
    scale_fill_viridis_d(name = "Version", guide = "none", option = "viridis", begin = 0.5, end = 1.0) +
    theme_bw() +
    theme(axis.title.x = element_blank(),
          axis.text.x = element_text(angle = 20, hjust = 0.8, vjust = 1))

update_theme_for_latex(plot.xp0.latency)

dev.off()

tab.latency <- format_data(data.latency) %>%
    select(stat_name, mean_stat_value, main_rate_limit, config_file) %>%
    pivot_wider(names_from = config_file, values_from = mean_stat_value) %>%
    mutate(Cassandra = Cassandra * NANOS_TO_MILLIS,
           Hector = Hector * NANOS_TO_MILLIS,
           abs_diff = Hector - Cassandra,
           rel_diff = (abs_diff / Cassandra) * 100) %>%
    arrange(stat_name, main_rate_limit) %>%
    mutate(Cassandra = paste0(as.numeric(num(floor(Cassandra * 1000) / 1000, digits = 3)), " ms"),
           Hector = paste0(as.numeric(num(floor(Hector * 1000) / 1000, digits = 3)), " ms"),
           abs_diff = paste0(as.numeric(num(floor(abs_diff * 1000) / 1000, digits = 3)), " ms"),
           rel_diff = paste0(as.numeric(num(floor(rel_diff * 100) / 100, digits = 2)), "%")) %>%
    rename("Stat." = stat_name,
           "Arrival rate" = main_rate_limit,
           "Cassandra" = Cassandra,
           "Hector" = Hector,
           "Abs. diff." = abs_diff,
           "Rel. diff." = rel_diff)

print(xtable(tab.latency, align = "ccccccc"),
      floating = FALSE,
      include.rownames = FALSE,
      booktabs = TRUE,
      hline.after = c(-1, 0, 2, 4, 6, nrow(tab.latency)),
      file = paste0(OUT, "/xp1_latency_table.tex"))
