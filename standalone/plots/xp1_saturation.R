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
             width = 0.4,
             colour = "black") +
    geom_errorbar(mapping = aes(x = config_file,
                                ymin = 1 / mean_high_speed * OPSS_TO_KOPSS,
                                ymax = 1 / mean_low_speed * OPSS_TO_KOPSS),
                  width = 0.1,
                  colour = "black") +
    coord_cartesian(ylim = c(0, NA)) +
    scale_x_discrete(name = "Version") +
    scale_y_continuous(name = "Throughput (kops/s)") +
    scale_fill_viridis_d(name = "Version", guide = "none", option = "viridis", begin = 0.5, end = 1.0) +
    theme_bw() +
    theme(axis.title.x = element_blank())

update_theme_for_latex(plot.xp0.throughput)

dev.off()

tab.throughput <- format_data(data.speed) %>%
    select(mean_speed, config_file) %>%
    pivot_wider(names_from = config_file, values_from = mean_speed) %>%
    mutate(label = "Throughput",
           Cassandra = 1 / Cassandra,
           Hector = 1 / Hector,
           abs_diff = Hector - Cassandra,
           rel_diff = (abs_diff / Cassandra) * 100) %>%
    relocate(label) %>%
    mutate(Cassandra = paste0(floor(Cassandra), " ops/s"),
           Hector = paste0(floor(Hector), " ops/s"),
           abs_diff = paste0(floor(abs_diff), " ops/s"),
           rel_diff = paste0(as.numeric(num(floor(rel_diff * 100) / 100, digits = 2)), "%")) %>%
    rename(" " = label,
           "Cassandra" = Cassandra,
           "Hector" = Hector,
           "Abs. diff." = abs_diff,
           "Rel. diff." = rel_diff)

print(xtable(tab.throughput, align = "cccccc"),
      floating = FALSE,
      include.rownames = FALSE,
      booktabs = TRUE,
      file = paste0(OUT, "/xp1_throughput_table.tex"))
