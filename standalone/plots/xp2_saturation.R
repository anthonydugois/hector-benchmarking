source("standalone/plots/include.R")

OUT <- ARGS[1]
DIR <- ARGS[2]
ARCHIVE <- ARGS[3]

df <- read_from_archive(DIR, ARCHIVE, .rm = TRUE)

data.speed <- df$latency_ts %>%
    group_by(id, run, host_address) %>%
    summarise(count = max(count), duration = max(time), .groups = "drop") %>%
    group_by(id, run) %>%
    summarise(count = sum(count), duration = max(duration), speed = duration / count, .groups = "drop")

data.read.all <- df$dstat_hosts %>%
    group_by(id, run, host_address) %>%
    summarise(read = sum(dsk_sda5__read), duration = max(time), rate = read / duration, .groups = "drop")

data.read.mean <- data.read.all %>%
    group_by(id, run) %>%
    summarise_mean(rate)

RUN_DURATION_MIN <- 10

format_speed <- function(.data) {
    config.levels <- c("xp3/cassandra-ds.yaml", "xp3/cassandra-c3.yaml", "xp3/cassandra-pa.yaml")
    config.labels <- c("DS", "C3", "PA")

    pop.levels <- c("ApproximatedZipf(600000000,0.1)", "ApproximatedZipf(600000000,1.5)")
    pop.labels <- c("$\\mathrm{Zipf}(0.1)$", "$\\mathrm{Zipf}(1.5)$")

    .data %>%
        inner_join(df$input, by = "id") %>%
        mutate(config_file = factor(config_file, levels = config.levels, labels = config.labels),
               key_dist = factor(key_dist, levels = pop.levels, labels = pop.labels))
}

tikz(file = paste0(OUT, "/xp2_throughput.tex"), width = 3.25, height = 1.6)

plot.xp3.throughput <- ggplot(data = format_speed(data.speed)) +
    geom_line(mapping = aes(x = run * RUN_DURATION_MIN,
                            y = 1 / speed * OPSS_TO_KOPSS,
                            colour = config_file),
              size = 0.6,
              alpha = 0.6) +
    geom_point(mapping = aes(x = run * RUN_DURATION_MIN,
                             y = 1 / speed * OPSS_TO_KOPSS,
                             colour = config_file,
                             shape = config_file),
               size = 0.6) +
    annotate(geom = "rect",
             xmin = 0,
             xmax = RUN_DURATION_MIN,
             ymin = 0,
             ymax = Inf,
             fill = "black",
             alpha = 0.1) +
    annotate(geom = "text",
             x = 0.5 * RUN_DURATION_MIN,
             y = 625,
             angle = 90,
             size = 1.8,
             colour = "black",
             alpha = 0.8,
             label = "N/A") +
    facet_wrap(vars(key_dist)) +
    coord_cartesian(xlim = c(0, NA),
                    ylim = c(0, NA)) +
    scale_x_continuous(name = "Runtime (min)") +
    scale_y_continuous(name = "Throughput (kops/s)",
                       breaks = seq(0, 1250, 250)) +
    scale_colour_discrete(name = "Strategy") +
    scale_shape_discrete(name = "Strategy") +
    theme_bw()

update_theme_for_latex(plot.xp3.throughput)

dev.off()

tab.throughput <- format_speed(data.speed %>%
                                   group_by(id) %>%
                                   summarise_mean(speed)) %>%
    mutate(mean_throughput = 1 / mean_speed,
           median_throughput = 1 / median_speed,
           min_throughput = 1 / max_speed,
           max_throughput = 1 / min_speed) %>%
    select(mean_throughput, median_throughput, min_throughput, max_throughput, key_dist, config_file) %>%
    pivot_longer(c(mean_throughput, median_throughput, min_throughput, max_throughput), names_to = "stat_name", values_to = "stat_value") %>%
    group_by(stat_name) %>%
    pivot_wider(names_from = config_file, values_from = stat_value) %>%
    relocate(stat_name, key_dist, DS, C3, PA) %>%
    mutate(stat_name = factor(stat_name,
                              levels = c("mean_throughput", "median_throughput", "min_throughput", "max_throughput"),
                              labels = c("Mean", "Median", "Min", "Max")),
           DS = floor(DS), C3 = floor(C3), PA = floor(PA)) %>%
    arrange(stat_name, key_dist) %>%
    rename("Stat." = stat_name,
           "Key popularity" = key_dist,
           "DS" = DS, "C3" = C3, "PA" = PA)

print(xtable(tab.throughput, align = "cccccc", digits = 0),
      floating = FALSE,
      include.rownames = FALSE,
      booktabs = TRUE,
      hline.after = c(-1, 0, 2, 4, 6, nrow(tab.throughput)),
      sanitize.text.function = identity,
      file = paste0(OUT, "/xp2_throughput_table.tex"))

format_read <- function(.data) {
    config.levels <- c("xp3/cassandra-ds.yaml", "xp3/cassandra-c3.yaml", "xp3/cassandra-pa.yaml")
    config.labels <- c("DS", "C3", "PA")

    pop.levels <- c("ApproximatedZipf(600000000,0.1)", "ApproximatedZipf(600000000,1.5)")
    pop.labels <- c("$\\mathrm{Zipf}(0.1)$", "$\\mathrm{Zipf}(1.5)$")

    .data %>%
        inner_join(df$input, by = "id") %>%
        mutate(config_file = factor(config_file, levels = config.levels, labels = config.labels),
               key_dist = factor(key_dist, levels = pop.levels, labels = pop.labels))
}

tikz(file = paste0(OUT, "/xp2_read.tex"), width = 3.25, height = 1.6)

plot.xp3.read <- ggplot(data = format_read(data.read.mean)) +
    geom_ribbon(mapping = aes(x = run * RUN_DURATION_MIN,
                              ymin = min_rate * B_TO_MB,
                              ymax = max_rate * B_TO_MB,
                              fill = config_file),
                alpha = 0.2) +
    geom_line(mapping = aes(x = run * RUN_DURATION_MIN,
                            y = mean_rate * B_TO_MB,
                            colour = config_file),
              size = 0.6,
              alpha = 0.6) +
    geom_point(mapping = aes(x = run * RUN_DURATION_MIN,
                             y = mean_rate * B_TO_MB,
                             colour = config_file,
                             shape = config_file),
               size = 0.6) +
    annotate(geom = "rect",
             xmin = 0,
             xmax = RUN_DURATION_MIN,
             ymin = 0,
             ymax = Inf,
             fill = "black",
             alpha = 0.1) +
    annotate(geom = "text",
             x = 0.5 * RUN_DURATION_MIN,
             y = 225,
             angle = 90,
             size = 1.8,
             colour = "black",
             alpha = 0.8,
             label = "N/A") +
    facet_wrap(vars(key_dist)) +
    coord_cartesian(xlim = c(0, NA),
                    ylim = c(0, NA)) +
    scale_x_continuous(name = "Runtime (min)") +
    scale_y_continuous(name = "Disk-read (MB/s)",
                       breaks = seq(0, 450, 100)) +
    scale_colour_discrete(name = "Strategy") +
    scale_fill_discrete(name = "Strategy") +
    scale_shape_discrete(name = "Strategy") +
    theme_bw()

update_theme_for_latex(plot.xp3.read)

dev.off()
