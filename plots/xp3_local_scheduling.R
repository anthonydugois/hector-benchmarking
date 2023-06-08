source("plots/include.R")

OUT <- ARGS[1]
DIR <- ARGS[2]
ARCHIVE <- ARGS[3]

df <- read_from_archive(DIR, ARCHIVE, .rm = TRUE)

get_rate <- function(n) {
    10000 + (n - 1) * 5000
}

data.latency <- df$latency %>%
    mutate(rate = get_rate(run),
           saturation = case_when(
               id == "xp3_1" & run <= 8 ~ "no",
               id == "xp3_1" & run > 8 ~ "yes",
               id == "xp3_2" & run <= 10 ~ "no",
               id == "xp3_2" & run > 10 ~ "yes"))

data.latency.small <- df$small_latency %>% mutate(rate = get_rate(run))

data.latency.large <- df$large_latency %>% mutate(rate = get_rate(run))

data.latency.type <- bind_rows(data.latency.small %>% mutate(type = "small"),
                               data.latency.large %>% mutate(type = "large"))

data.speed <- df$latency_ts %>%
    group_by(id, run, host_address) %>%
    summarise(count = max(count), duration = max(time), .groups = "drop") %>%
    group_by(id, run) %>%
    summarise(count = sum(count), duration = max(duration), speed = duration / count, .groups = "drop")

data.throughput <- data.speed %>% mutate(rate = get_rate(run),
                                         throughput = 1 / speed,
                                         saturation = case_when(
                                             id == "xp3_1" & run <= 7 ~ "no",
                                             id == "xp3_1" & run > 7 ~ "yes",
                                             id == "xp3_2" & run <= 9 ~ "no",
                                             id == "xp3_2" & run > 9 ~ "yes"))

COLOURS <- hue_pal()(2)

format_throughput <- function(.data) {
    config.levels <- c("xp3/cassandra-ds-fifo-4.yaml", "xp3/cassandra-ds-rml-4.yaml")
    config.labels <- c("FCFS", "RML")

    filtered_runs <- seq(from = 1, to = 11)

    .data %>%
        inner_join(df$input, by = "id") %>%
        filter(run %in% filtered_runs) %>%
        mutate(config_file = factor(config_file, levels = config.levels, labels = config.labels))
}

tikz(file = paste0(OUT, "/xp3_throughput.tex"), width = 3.2, height = 1.6)

plot.xp3.throughput <- ggplot(data = format_throughput(data.throughput)) +
    geom_col(mapping = aes(x = rate * OPSS_TO_KOPSS,
                           y = throughput * OPSS_TO_KOPSS,
                           fill = config_file,
                           alpha = saturation),
             width = 3,
             position = position_dodge2(padding = 0.25)) +
    annotate(geom = "segment",
             x = -Inf,
             xend = Inf,
             y = 40,
             yend = 40,
             linetype = "dashed",
             colour = COLOURS[[1]],
             alpha = 0.6) +
    annotate(geom = "segment",
             x = -Inf,
             xend = Inf,
             y = 50,
             yend = 50,
             linetype = "dashed",
             colour = COLOURS[[2]],
             alpha = 0.6) +
    annotate(geom = "label",
             x = 15,
             y = 40,
             size = 2.2,
             colour = COLOURS[[1]],
             label = "FCFS",
             label.padding = unit(0.1, "lines")) +
    annotate(geom = "label",
             x = 15,
             y = 50,
             size = 2.2,
             colour = COLOURS[[2]],
             label = "RML",
             label.padding = unit(0.1, "lines")) +
    coord_cartesian(ylim = c(0, 55)) +
    scale_x_continuous(name = "Arrival rate (kops/s)", breaks = seq(10, 60, 10)) +
    scale_y_continuous(name = "Throughput (kops/s)", breaks = seq(0, 50, 10)) +
    scale_fill_discrete(name = "Strategy") +
    scale_alpha_manual(values = c(1, 0.4), guide = "none") +
    theme_bw()

update_theme_for_latex(plot.xp3.throughput)

dev.off()

format_latency <- function(.data) {
    stats.levels <- c("mean", "p50", "p90", "p99.0")
    stats.labels <- c("Mean", "Median", "P90", "P99")

    config.levels <- c("xp3/cassandra-ds-fifo-4.yaml", "xp3/cassandra-ds-rml-4.yaml")
    config.labels <- c("FCFS", "RML")

    filtered_runs <- seq(from = 1, to = 11)

    .data %>%
        inner_join(df$input, by = "id") %>%
        filter(run %in% filtered_runs,
               stat_name %in% stats.levels) %>%
        mutate(stat_name = factor(stat_name, levels = stats.levels, labels = stats.labels),
               config_file = factor(config_file, levels = config.levels, labels = config.labels))
}

tikz(file = paste0(OUT, "/xp3_latency.tex"), width = 3.4, height = 2.1)

plot.xp3.latency <- ggplot() +
    geom_line(data = format_latency(data.latency) %>% filter(saturation == "no"),
              mapping = aes(x = rate * OPSS_TO_KOPSS,
                            y = stat_value * NANOS_TO_MILLIS,
                            colour = config_file,
                            group = config_file),
              size = 0.6,
              alpha = 0.6) +
    geom_point(data = format_latency(data.latency),
               mapping = aes(x = rate * OPSS_TO_KOPSS,
                             y = stat_value * NANOS_TO_MILLIS,
                             colour = config_file,
                             shape = config_file,
                             alpha = saturation),
               size = 0.6) +
    facet_wrap(vars(stat_name), scales = "free") +
    coord_cartesian(ylim = c(0, NA)) +
    scale_x_continuous(name = "Arrival rate (kops/s)", breaks = seq(10, 60, 10)) +
    scale_y_continuous(name = "Latency (ms)") +
    scale_colour_discrete(name = "Strategy") +
    scale_shape_discrete(name = "Strategy") +
    scale_alpha_manual(values = c(1, 0.4), guide = "none") +
    theme_bw()

update_theme_for_latex(plot.xp3.latency)

dev.off()

format_small_large <- function(.data) {
    stats.levels <- c("mean")
    stats.labels <- c("Mean")

    config.levels <- c("xp3/cassandra-ds-fifo-4.yaml", "xp3/cassandra-ds-rml-4.yaml")
    config.labels <- c("FCFS", "RML")

    type.levels <- c("large", "small")
    type.labels <- c("Large", "Small")

    filtered_runs <- seq(from = 7, to = 10)

    .data %>%
        inner_join(df$input, by = "id") %>%
        filter(run %in% filtered_runs,
               stat_name %in% stats.levels) %>%
        mutate(stat_name = factor(stat_name, levels = stats.levels, labels = stats.labels),
               config_file = factor(config_file, levels = config.levels, labels = config.labels),
               type = factor(type, levels = type.levels, labels = type.labels))
}

tikz(file = paste0(OUT, "/xp3_small_large.tex"), width = 3.4, height = 1.25)

plot.xp3.small_large <- ggplot(data = format_small_large(data.latency.type)) +
    geom_col(mapping = aes(x = config_file,
                           y = stat_value * NANOS_TO_MILLIS,
                           fill = type),
             width = 0.6,
             position = position_dodge2(padding = 0.25)) +
    facet_wrap(vars(paste0(rate * OPSS_TO_KOPSS, " kops/s")), scales = "free", ncol = 4) +
    scale_x_discrete(name = "Strategy") +
    scale_y_continuous(name = "Latency (ms)") +
    scale_fill_discrete(name = "Type") +
    theme_bw() +
    theme(axis.title.x = element_blank(),
          legend.position = "bottom")

update_theme_for_latex(plot.xp3.small_large)

dev.off()
